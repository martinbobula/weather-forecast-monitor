from pathlib import Path
import sys
from src.ingest.load_one_raw_file import load_one_raw_file  # adapt import to your project

RAW_DIR = Path("data/raw")

def main() -> int:
    files = sorted(RAW_DIR.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not files:
        print("No raw json files found in data/raw/")
        return 0

    newest = files[0]
    print(f"Loading newest raw file: {newest}")
    load_one_raw_file(str(newest))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
