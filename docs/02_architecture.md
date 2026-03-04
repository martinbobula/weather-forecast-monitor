# Architecture

## Stack
- Python (ingestion, orchestration helpers, notifications)
- DuckDB (local analytical database)
- DuckDB SQL (modeling, monitoring, alert rules, morning brief)
- Bash (single-run orchestrator)
- macOS `launchd` (scheduling)
- Telegram Bot API (notifications)

## End-to-end flow
1. **Fetch forecast (Python)**
   - `src/ingest/fetch_forecast.py`
   - Calls Open-Meteo for Prague hourly forecast variables
   - Wraps response in a standard envelope and writes JSON to `data/raw/`

2. **Load raw snapshot (Python → DuckDB)**
   - `src/ingest/load_latest_raw.py` → `src/ingest/load_one_raw_file.py`
   - Computes a payload content hash (sha256)
   - Writes to:
     - `snapshot_registry` (ledger of snapshots + hashes)
     - `raw_snapshots` (raw payload storage, idempotent per raw file)

3. **Normalize to hourly rows (SQL-first)**
   - `sql/models/core/01_build_snapshots_hourly.sql`
   - Flattens JSON arrays into `snapshots_hourly` (one row per forecast hour)

4. **Monitoring (SQL)**
   - `sql/models/monitoring/01_snapshot_health.sql`
   - Computes:
     - snapshots count today
     - missing hours 06:00–19:00 local
     - % of hourly hashes changed vs previous snapshot
   - Writes to `monitoring_snapshot_health`

5. **Alerts (SQL + Python)**
   - Rain next 6h:
     - `01_rain_next6h_decision.sql` (change-aware decision)
     - `02_rain_next6h_gated.sql` (2-hour cooldown gating)
   - Wind next 6h:
     - `03_wind_next6h_decision.sql` (spike logic)
     - `04_wind_next6h_gated.sql` (2-hour cooldown gating)
   - `src/notify/print_alerts.py` reads gated tables, prints, and writes to `alert_log`

6. **Morning brief (SQL + Python)**
   - `sql/models/brief/03_morning_brief_v2_final.sql` aggregates next 12 hours + dayparts
   - `src/notify/print_morning_brief.py`:
     - gates sending (after 07:00 local)
     - sends once per day (tracked in `brief_log`)
     - supports `--dry-run` and `--force`

7. **Orchestration and scheduling**
   - `scripts/run_weather_pipeline.sh` runs all steps for a single pipeline run, with logging
   - A macOS LaunchAgent (plist outside repo) triggers runs hourly + at login

## Why SQL-first here
Business logic is easiest to trust when it is:
- centralized (SQL models)
- transparent (reviewable rules)
- reproducible (rebuild tables from raw snapshots)

This mirrors a common analytics workflow: “warehouse tables + models + downstream outputs.”

## Productionization path (high level)
This repo is local-first. A realistic next step would be:
- schedule via a cloud cron (GitHub Actions / VM cron / managed scheduler)
- store secrets in a secret manager
- move from local DuckDB file to a managed database (optional)
- add automated tests and run monitoring checks on each run
