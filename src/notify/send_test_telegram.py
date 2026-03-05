import sys
from pathlib import Path

# Add project root to path so imports work
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from src.notify.telegram import send_telegram_message


def main() -> int:
    send_telegram_message("✅ Python test: Weather Updates can send Telegram messages.")
    print("Sent test Telegram message.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())