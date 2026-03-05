import os
import requests
from dotenv import load_dotenv


def send_telegram_message(message: str) -> None:
    """
    Sends a Telegram message using Bot API.

    Requires env vars:
      - TELEGRAM_BOT_TOKEN
      - TELEGRAM_CHAT_ID
    """
    load_dotenv()
    
    token = os.getenv("TELEGRAM_BOT_TOKEN")
    chat_id = os.getenv("TELEGRAM_CHAT_ID")

    if not token or not chat_id:
        raise RuntimeError("Missing TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID in environment")

    url = f"https://api.telegram.org/bot{token}/sendMessage"
    resp = requests.post(
        url,
        json={
            "chat_id": chat_id,
            "text": message,
            "disable_web_page_preview": True,
        },
        timeout=15,
    )

    if resp.status_code != 200:
        try:
            error_data = resp.json()
            error_desc = error_data.get("description", resp.text)
            
            # Provide helpful guidance for common errors
            if "bots can't send messages to bots" in error_desc:
                raise RuntimeError(
                    f"Telegram error: {error_desc}\n"
                    "Fix: TELEGRAM_CHAT_ID must be your personal user chat ID, not a bot's chat ID.\n"
                    "To get your chat ID: Start a chat with @userinfobot on Telegram."
                )
            elif "chat not found" in error_desc.lower():
                raise RuntimeError(
                    f"Telegram error: {error_desc}\n"
                    "Fix: The bot hasn't received a message from this chat yet. "
                    "Send a message to your bot first, then try again."
                )
            else:
                raise RuntimeError(f"Telegram send failed ({resp.status_code}): {error_desc}")
        except (ValueError, KeyError):
            # Fallback if response isn't JSON
            raise RuntimeError(f"Telegram send failed: {resp.status_code} {resp.text}")
