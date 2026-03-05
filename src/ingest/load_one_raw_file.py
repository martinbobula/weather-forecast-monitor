from __future__ import annotations

import json
import os
import sys
from pathlib import Path
import hashlib


import duckdb
from dotenv import load_dotenv


def load_one_raw_file(fp: str, db_path: str | None = None) -> None:
    """
    Load a single raw JSON snapshot into DuckDB.

    Exposed as a function so it can be imported from other modules
    (e.g. src.ingest.load_latest_raw).
    """
    load_dotenv()
    if db_path is None:
        db_path = os.getenv("DUCKDB_PATH", "data/duckdb/weather.duckdb")
    obj = json.loads(Path(fp).read_text(encoding="utf-8"))
    payload_str = json.dumps(obj["payload"], sort_keys=True)
    content_hash = hashlib.sha256(payload_str.encode("utf-8")).hexdigest()

    con = duckdb.connect(db_path)

    # Ensure snapshot_registry table exists
    con.execute("""
    CREATE TABLE IF NOT EXISTS snapshot_registry (
        location_name VARCHAR,
        snapshot_time_utc TIMESTAMP,
        raw_file VARCHAR PRIMARY KEY,
        content_hash VARCHAR,
        inserted_at_utc TIMESTAMP DEFAULT NOW()
    );
    """)

    # Check previous content hash for this location
    prev = con.execute(
        """
        SELECT content_hash
        FROM snapshot_registry
        WHERE location_name = ?
        ORDER BY snapshot_time_utc DESC
        LIMIT 1
        """,
        [obj["location"]["name"]],
    ).fetchone()

    prev_hash = prev[0] if prev else None
    changed = (prev_hash != content_hash) if prev_hash else True
    print(f"Content changed vs previous snapshot: {changed}")

    # Insert into snapshot_registry
    con.execute(
        """
        INSERT INTO snapshot_registry (location_name, snapshot_time_utc, raw_file, content_hash)
        VALUES (?, ?, ?, ?)
        """,
        [
            obj["location"]["name"],
            obj["snapshot_time_utc"],
            fp,
            content_hash,
        ],
    )

    # Ensure raw_snapshots table exists
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

    # Skip if already loaded
    already = con.execute(
        "SELECT COUNT(*) FROM raw_snapshots WHERE raw_file = ?",
        [fp],
    ).fetchone()[0]

    if already > 0:
        print(f"Already loaded, skipping: {fp}")
        con.close()
        return

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

    con.close()
    print(f"Inserted 1 raw snapshot: {fp}")


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit("Usage: python src/ingest/load_one_raw_file.py <path_to_raw_json>")

    fp = sys.argv[1]
    load_one_raw_file(fp)


if __name__ == "__main__":
    main()
