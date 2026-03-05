import sys
import duckdb
from pathlib import Path

# Add project root to path so imports work
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from src.notify.telegram import send_telegram_message

DB_PATH = Path("data/duckdb/weather.duckdb")
SQL_PATH = Path("sql/models/brief/03_morning_brief_v2_final.sql")


def format_morning_brief_v2(row: dict) -> str:
    temp = row.get("avg_temp_c_12h")
    feels = row.get("avg_feels_like_c_12h")
    sky = (row.get("sky_text") or "unknown").strip()

    rain_possible = bool(row.get("rain_possible"))
    max_wind = row.get("max_wind_kmh_12h")
    dayparts_line = (row.get("dayparts_line") or "").strip()

    lines = []

    # 1) Temp + feels
    if temp is not None and feels is not None:
        lines.append(f"Morning brief (Prague): {temp}°C (feels like {feels}°C)")
    elif temp is not None:
        lines.append(f"Morning brief (Prague): {temp}°C")
    else:
        lines.append("Morning brief (Prague): (temperature unavailable)")

    # 2) Sky condition
    lines.append(f"Sky: {sky}")

    # 3) Rain only if relevant
    if rain_possible:
        lines.append("Rain: possible")

    # 4) Wind only if relevant
    try:
        if max_wind is not None and float(max_wind) >= 25:
            lines.append(f"Wind: up to {int(round(float(max_wind)))} km/h")
    except Exception:
        pass

    # 5) Dayparts (one extra line max)
    if dayparts_line:
        lines.append(f"Dayparts: {dayparts_line}")

    return "\n".join(lines)


def fetch_one_row_as_dict(con: duckdb.DuckDBPyConnection, sql_text: str) -> dict | None:
    res = con.execute(sql_text)
    row = res.fetchone()
    if row is None:
        return None
    cols = [d[0] for d in res.description]
    return dict(zip(cols, row))


def main() -> int:
    dry_run = "--dry-run" in sys.argv
    force = "--force" in sys.argv  # bypass "already sent" check (but still logs unless dry-run)

    con = duckdb.connect(str(DB_PATH))

    today_local = con.execute(
        "SELECT (now() AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Prague')::DATE"
    ).fetchone()[0]

    # Prague local hour (integer 0–23)
    now_hour_local = con.execute(
        "SELECT extract('hour' FROM (now() AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Prague'))::INT"
    ).fetchone()[0]

    # Only send after 07:00 local time (unless dry-run or force)
    if (not dry_run) and (not force) and (now_hour_local < 7):
        print(f"Before 07:00. Now: {now_hour_local}:xx. Waiting for 07:00.")
        con.close()
        return 0

    already_sent = con.execute(
        """
        SELECT COUNT(*)
        FROM brief_log
        WHERE sent_date_local = ?
          AND location_name = 'Prague'
        """,
        [today_local],
    ).fetchone()[0] > 0

    if already_sent and (not force) and (not dry_run):
        print("Morning brief already sent today. Skipping.")
        print("Tip: run `python src/notify/print_morning_brief.py --dry-run` to preview anyway.")
        con.close()
        return 0

    sql_text = SQL_PATH.read_text(encoding="utf-8")
    data = fetch_one_row_as_dict(con, sql_text)

    if not data:
        print("No morning brief data available.")
        con.close()
        return 0

    msg = format_morning_brief_v2(data)
    print(msg)

    if dry_run:
        print("\n(dry-run: not sending to Telegram, not writing to brief_log)")
        con.close()
        return 0

    # Send to Telegram first. Only log if send succeeded.
    send_telegram_message(msg)
    print("Sent to Telegram.")

    con.execute(
        """
        INSERT INTO brief_log (sent_date_local, sent_time_utc, location_name, message)
        VALUES (?, now(), 'Prague', ?)
        """,
        [today_local, msg],
    )

    con.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())