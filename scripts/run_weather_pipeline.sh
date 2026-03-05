#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/Users/martinbobula/Data projects/Weather Updates"
VENV_DIR="$PROJECT_DIR/.venv"
LOG_DIR="$PROJECT_DIR/data/exports/logs"
TS="$(date '+%Y-%m-%d_%H-%M-%S')"
LOG_FILE="$LOG_DIR/pipeline_$TS.log"

mkdir -p "$LOG_DIR"
cd "$PROJECT_DIR"

# Load .env so launchd runs have TELEGRAM_* variables
if [ -f ".env" ]; then
  set -a
  source ".env"
  set +a
fi
# Run only 06:00–19:59 local time
HOUR="$(date '+%H')"
HOUR=$((10#$HOUR))
if [[ $HOUR -lt 6 || $HOUR -gt 19 ]]; then
  echo "Outside active hours (06–19). Exiting."
  exit 0
fi

{
  echo "=== RUN START: $(date) ==="
  echo "PWD: $(pwd)"
  echo "User: $(whoami)"

  if [[ -f "$VENV_DIR/bin/activate" ]]; then
    source "$VENV_DIR/bin/activate"
  else
    echo "ERROR: venv not found at $VENV_DIR"
    exit 1
  fi

  echo "--- Fetch ---"
  python src/ingest/fetch_forecast.py

  echo "--- Load latest raw ---"
  python -m src.ingest.load_latest_raw

  echo "--- Build snapshots_hourly (SQL-first) ---"
python src/ingest/run_sql.py sql/models/core/01_build_snapshots_hourly.sql


  echo "--- Monitoring SQL ---"
  python src/ingest/run_sql.py sql/models/monitoring/01_snapshot_health.sql

  echo "--- Init alert log (safe) ---"
python src/ingest/run_sql.py sql/models/alerts/00_init_alert_log.sql

echo "--- Alert model: rain next 6h ---"
python src/ingest/run_sql.py sql/models/alerts/01_rain_next6h_decision.sql
echo "--- Alert gating: rain next 6h ---"
python src/ingest/run_sql.py sql/models/alerts/02_rain_next6h_gated.sql

echo "--- Alert model: wind next 6h ---"
python src/ingest/run_sql.py sql/models/alerts/03_wind_next6h_decision.sql
echo "--- Alert gating: wind next 6h ---"
python src/ingest/run_sql.py sql/models/alerts/04_wind_next6h_gated.sql

echo "--- Alert output ---"
python src/notify/print_alerts.py

echo "--- Morning brief init ---"
python src/ingest/run_sql.py sql/models/brief/00_init_brief_log.sql

echo "--- Morning brief model ---"
python src/ingest/run_sql.py sql/models/brief/03_morning_brief_v2_final.sql

echo "--- Morning brief output ---"
python src/notify/print_morning_brief.py

  echo "=== RUN END: $(date) ==="
} 2>&1 | tee -a "$LOG_FILE"
