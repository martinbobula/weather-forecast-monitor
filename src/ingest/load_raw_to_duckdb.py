from __future__ import annotations

import glob
import json
import os
import sys
from pathlib import Path

import duckdb
from dotenv import load_dotenv


def main() -> None:
    load_dotenv()

    db_path = os.getenv("DUCKDB_PATH", "data/duckdb/weather.duckdb")
    raw_dir = Path("data/raw")

    files = sorted(glob.glob(str(raw_dir / "*.json")))
    if not files:
        raise FileNotFoundError("No raw snapshot JSON files found in data/raw/")

    con = duckdb.connect(db_path)

    # Raw landing table in the warehouse
    con.execute("""
    CREATE TABLE IF NOT EXISTS raw_snapshots (
        snapshot_time_utc TIMESTAMP,
        location_name VARCHAR,
        latitude DOUBLE,
        longitude DOUBLE,
        timezone VARCHAR,
        payload_json JSON,
        source VARCHAR,
        endpoint VARCHAR,
        raw_file VARCHAR
    );
    """)

    inserted = 0

    for fp in files:
        obj = json.loads(Path(fp).read_text(encoding="utf-8"))

        con.execute(
            """
            INSERT INTO raw_snapshots
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                obj["snapshot_time_utc"],
                obj["location"]["name"],
                obj["location"]["lat"],
                obj["location"]["lon"],
                obj["location"]["timezone"],
                json.dumps(obj["payload"]),
                obj.get("source", "open-meteo"),
                obj.get("endpoint", ""),
                fp,
            ],
        )
        inserted += 1

    con.close()
    print(f"Inserted {inserted} raw snapshots into raw_snapshots.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
