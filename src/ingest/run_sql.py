from __future__ import annotations

import os
import sys
from pathlib import Path

import duckdb
from dotenv import load_dotenv


def main() -> None:
    load_dotenv()

    if len(sys.argv) < 2:
        raise SystemExit("Usage: python src/ingest/run_sql.py <path_to_sql_file>")

    sql_path = Path(sys.argv[1])
    if not sql_path.exists():
        raise FileNotFoundError(f"SQL file not found: {sql_path}")

    db_path = os.getenv("DUCKDB_PATH", "data/duckdb/weather.duckdb")
    sql = sql_path.read_text(encoding="utf-8").strip()
    
    if not sql:
        raise ValueError(f"SQL file is empty: {sql_path}")

    con = duckdb.connect(db_path)
    
    try:
        # Try to use fetchdf() if pandas is available
        try:
            df = con.execute(sql).fetchdf()
            print(df)
        except Exception as e:
            # Fall back to fetchall() if pandas is not available
            if "pandas" in str(e).lower() or "numpy" in str(e).lower() or "fetchdf" in str(e).lower():
                result = con.execute(sql)
                results = result.fetchall()
                columns = result.description
                if columns:
                    col_names = [col[0] for col in columns]
                    # Print header
                    print(" | ".join(str(c) for c in col_names))
                    print("-" * (sum(len(str(c)) for c in col_names) + 3 * len(col_names)))
                    # Print rows
                    for row in results:
                        print(" | ".join(str(c) for c in row))
                else:
                    for row in results:
                        print(row)
            else:
                raise
    finally:
        con.close()


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
