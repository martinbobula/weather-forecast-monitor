import duckdb
from pathlib import Path
from src.notify.telegram import send_telegram_message

DB_PATH = Path("data/duckdb/weather.duckdb")


def table_exists(con: duckdb.DuckDBPyConnection, name: str) -> bool:
    return con.execute(
        """
        SELECT COUNT(*)
        FROM information_schema.tables
        WHERE table_schema = 'main' AND table_name = ?
        """,
        [name],
    ).fetchone()[0] > 0


def run_sql_file(con: duckdb.DuckDBPyConnection, path: Path) -> None:
    if path.exists():
        con.execute(path.read_text(encoding="utf-8"))


def ensure_alert_models(
    con: duckdb.DuckDBPyConnection,
    project_root: Path,
    decision_table: str,
    decision_sql: str,
    gated_table: str,
    gated_sql: str,
) -> None:
    # 1) decision table
    if not table_exists(con, decision_table):
        run_sql_file(con, project_root / decision_sql)

    # 2) alert_log (shared)
    if not table_exists(con, "alert_log"):
        run_sql_file(con, project_root / "sql/models/alerts/00_init_alert_log.sql")

    # 3) gated table
    if not table_exists(con, gated_table):
        run_sql_file(con, project_root / gated_sql)


def main() -> int:
    con = duckdb.connect(str(DB_PATH))
    project_root = Path(__file__).parent.parent.parent

    # ---- Ensure required tables for RAIN ----
    ensure_alert_models(
        con=con,
        project_root=project_root,
        decision_table="alert_rain_next6h_decision",
        decision_sql="sql/models/alerts/01_rain_next6h_decision.sql",
        gated_table="alert_rain_next6h_gated",
        gated_sql="sql/models/alerts/02_rain_next6h_gated.sql",
    )

    # ---- Ensure required tables for WIND ----
    ensure_alert_models(
        con=con,
        project_root=project_root,
        decision_table="alert_wind_next6h_decision",
        decision_sql="sql/models/alerts/03_wind_next6h_decision.sql",
        gated_table="alert_wind_next6h_gated",
        gated_sql="sql/models/alerts/04_wind_next6h_gated.sql",
    )

    # ---- RAIN output ----
    row = con.execute(
        """
        SELECT should_send_after_gating, current_snapshot_utc
        FROM alert_rain_next6h_gated
        LIMIT 1
        """
    ).fetchone()

    rain_should_send = bool(row[0]) if row and row[0] is not None else False
    rain_snapshot_time_utc = row[1] if row else None

    if rain_should_send:
        msg = "ALERT: Rain expected in next 6 hours."
        print(msg)
        con.execute(
            """
            INSERT INTO alert_log (sent_time_utc, alert_type, snapshot_time_utc, message)
            VALUES (now(), 'rain_next6h', ?, ?)
            """,
            [rain_snapshot_time_utc, msg],
        )
    else:
        print("No rain alert (after gating).")

    # ---- WIND output ----
    row = con.execute(
        """
        SELECT should_send_after_gating, current_snapshot_utc, current_max_wind_next6h
        FROM alert_wind_next6h_gated
        LIMIT 1
        """
    ).fetchone()

    wind_should_send = bool(row[0]) if row and row[0] is not None else False
    wind_snapshot_time_utc = row[1] if row else None
    wind_max = row[2] if row else None

    if wind_should_send:
        # wind_max can be None in edge cases; guard formatting
        if wind_max is None:
            msg = "ALERT: Wind spike expected in next 6 hours."
        else:
            msg = f"ALERT: Wind spike expected (max ~{float(wind_max):.0f} km/h in next 6h)."
        print(msg)
        con.execute(
            """
            INSERT INTO alert_log (sent_time_utc, alert_type, snapshot_time_utc, message)
            VALUES (now(), 'wind_next6h', ?, ?)
            """,
            [wind_snapshot_time_utc, msg],
        )
    else:
        print("No wind alert (after gating).")

    con.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())