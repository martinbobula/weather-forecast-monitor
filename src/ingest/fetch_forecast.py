from __future__ import annotations

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import requests
from dotenv import load_dotenv


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def main() -> None:
    load_dotenv()

    base_url = os.getenv("OPEN_METEO_BASE_URL", "https://api.open-meteo.com/v1/forecast")

    lat = float(os.environ["PRAGUE_LAT"])
    lon = float(os.environ["PRAGUE_LON"])
    tz = os.getenv("TIMEZONE", "Europe/Prague")

    params = {
        "latitude": lat,
        "longitude": lon,
        "hourly": ",".join(
            ["temperature_2m", "apparent_temperature", "precipitation", "windspeed_10m", "cloudcover"]
        ),
        "timezone": tz,
        "timeformat": "iso8601",
    }

    snapshot_time_utc = utc_now_iso()
    r = requests.get(base_url, params=params, timeout=30)
    r.raise_for_status()
    payload = r.json()

    envelope = {
        "snapshot_time_utc": snapshot_time_utc,
        "source": "open-meteo",
        "endpoint": base_url,
        "location": {"name": "Prague", "lat": lat, "lon": lon, "timezone": tz},
        "payload": payload,
    }

    out_dir = Path("data/raw")
    out_dir.mkdir(parents=True, exist_ok=True)

    safe_ts = snapshot_time_utc.replace(":", "").replace("-", "")
    out_path = out_dir / f"forecast_prague_{safe_ts}Z.json"
    out_path.write_text(json.dumps(envelope, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"Saved raw snapshot: {out_path}")


if __name__ == "__main__":
    try:
        main()
    except KeyError as e:
        print(f"Error: Missing required environment variable: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
