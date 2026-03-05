from __future__ import annotations

import os
import sys
from pathlib import Path

import duckdb
from dotenv import load_dotenv


def main() -> None:
    load_dotenv()

    db_path = os.getenv("DUCKDB_PATH", "data/duckdb/weather.duckdb")
    Path(db_path).parent.mkdir(parents=True, exist_ok=True)

    con = duckdb.connect(db_path)

    # Minimal metadata table: helps with debugging and "ops" mindset
    con.execute("""
    CREATE TABLE IF NOT EXISTS etl_runs (
        run_id VARCHAR,
        run_time_utc TIMESTAMP,
        note VARCHAR
    );
    """)

    con.close()
    print(f"DuckDB ready at: {db_path}")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
