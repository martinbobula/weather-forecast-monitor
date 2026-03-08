# Weather Forecast Monitor (Prague)

A local, SQL-first weather pipeline that turns a public forecast API into **decision-support alerts** and a daily **morning brief**.

The project is built around a real use case (me / my girlfriend / friends in Prague): the goal is to **avoid being surprised by meaningful weather changes**, not to constantly monitor forecasts. Instead of repeatedly checking weather apps, the pipeline detects **new or significant forecast changes** (rain risk, wind spikes) and delivers concise notifications.

This repository is intentionally **simple but trustworthy**: it focuses on clear data layers, transparent business rules in SQL, and reliability patterns (idempotency, monitoring, cooldown gating) rather than UI, ML, or scale.

This project is actively evolving. The current version demonstrates the core architecture and decision logic of the pipeline. Additional improvements (evaluation metrics, configuration refactoring, and new alert signals) are listed in the Roadmap section.

---

## Executive summary

**Problem (user + decision):**
We check the weather to decide what to wear, whether to bring a rain jacket, and whether wind/rain will disrupt plans. The pain is not “lack of information” — it’s **noise, last-minute surprises, and forgetting to check the forecast when it actually matters**. This project converts forecasts into **actionable signals**:
- “Rain became likely within the next 6 hours (new information).”
- “Wind risk spiked compared to the previous forecast.”
- “Morning brief: what the next 12 hours look like, including dayparts (morning/noon/afternoon/evening).”
  
**Solution (what the pipeline does):**
- Fetches hourly forecasts from Open-Meteo
- Stores raw JSON snapshots on disk (raw archive)
- Loads + normalizes them into DuckDB tables (SQL-first modeling)
- Runs monitoring checks (missing hours, forecast change rate)
- Computes **change-aware alerts** (rain/wind) and applies a **2-hour cooldown**
- Generates a daily “morning brief” text summary
- Prints to stdout and/or sends notifications to Telegram
- Runs on a schedule via macOS `launchd` (or manually via a bash script)

**Success criteria (how “good” is judged):**
- Alerts are **infrequent enough to remain trusted**, but early enough to prevent surprises
- Alerts trigger on **meaningful forecast changes**, not repeated identical predictions
- Morning brief provides a concise, decision-ready overview of the next 12 hours
- Pipeline runs are **repeatable, traceable, and debuggable**
- Data transformations are transparent and auditable (SQL-first modeling)

**Non-goals (intentional):**
- No UI or mobile app
- No ML forecasting (uses Open-Meteo as the forecast provider)
- No multi-city scale (single-location template first)
- No cloud deployment in this repo (see roadmap for productionization path)

## Why this project exists

Many real-world data problems involve turning **external APIs into reliable decision-support signals**.

This repository demonstrates a small but realistic version of that pattern:

API → Raw archive → Modeled tables → Monitoring → Alerts → Notifications

The goal is not weather prediction itself, but building a **transparent and reliable data pipeline** that converts external data into actionable information.

---

## Architecture at a glance

**Stack:** Python + DuckDB + SQL + Bash + macOS `launchd` + Telegram Bot API

**End-to-end flow (local, SQL-first):**
1. **Ingest** hourly forecast from Open-Meteo (Python)
2. **Raw archive (Bronze):** store response as a timestamped JSON snapshot on disk + load into DuckDB
3. **Normalize (Silver):** flatten hourly arrays into a row-based `snapshots_hourly` table (DuckDB SQL)
4. **Monitor:** write snapshot health metrics (missing hours, change rate) into `monitoring_snapshot_health`
5. **Decide + gate alerts (Gold):**
   - change-aware *rain next 6 hours* alert
   - *wind spike next 6 hours* alert
   - 2-hour cooldown to prevent noise
6. **Communicate:** print to stdout and/or send Telegram notifications (alerts + morning brief)

> See: `docs/02_architecture.md` for the component-level breakdown and `docs/03_data_model.md` for tables and lineage.

---

## Reliability & Data Quality

Although this is a local project, it is structured with production-style thinking:

### 1. Idempotent Raw Loading

Each raw forecast snapshot:

- Is stored as a timestamped JSON file
- Is hashed (`sha256`) based on payload content
- Is registered in `snapshot_registry`
- Is only inserted into `raw_snapshots` once

If the same raw file is processed again, it is safely skipped.

This prevents duplication and ensures reproducibility.

---

### 2. Layered Data Modeling (Bronze → Silver → Gold)

The pipeline follows a simplified warehouse pattern:

- **Bronze**  
  Raw JSON snapshots stored on disk and in `raw_snapshots`.

- **Silver**  
  `snapshots_hourly` — flattened, row-based hourly forecast data.

- **Gold**  
  Decision-support tables:
  - `monitoring_snapshot_health`
  - alert decision + gated tables
  - `alert_log`
  - `brief_log`

Business logic (alerts, dayparts, monitoring) is expressed in SQL for transparency and auditability.

---

### 3. Monitoring & Health Checks

Each run writes a monitoring row including:

- Number of snapshots today
- Missing forecast hours (06:00–19:00)
- % of hourly forecast values that changed compared to previous snapshot

This allows inspection of:
- Forecast stability
- Data freshness
- Gaps in ingestion

---

### 4. Alert Noise Reduction

Alerts are:

- **Change-aware** (only when new information appears)
- **Cooldown-gated** (2-hour suppression window)
- Logged for traceability

This reduces alert fatigue and improves trust in notifications.

---

### 5. Time Gating & Operational Control

- Pipeline runs only between 06:00–19:59 local time
- Morning brief sends once per day (after 07:00)
- `--dry-run` and `--force` flags allow safe testing

This ensures predictable behavior and safe iteration.

---

## Alert Evaluation & Usefulness

This project is not about predicting weather — it is about delivering **useful signals**.

Alert quality can be evaluated using:

### 1. Frequency
- Are alerts rare enough to remain trusted?
- If alerts trigger every hour, the threshold is too sensitive.

### 2. Change Meaningfulness
- Do alerts reflect new information (vs repeated identical forecast)?
- Change-aware logic ensures alerts trigger only when the forecast meaningfully changes.

### 3. Timeliness
- Does the alert arrive early enough to adjust plans?
- Example: rain alert within the next 6 hours is actionable.

### 4. False Positives vs Missed Signals
- Too many alerts → noise.
- Too few alerts → missed events.
- Thresholds (wind ≥ 30 km/h, +15 km/h spike, etc.) can be tuned.

Future improvement: introduce measurable evaluation metrics such as:
- Alerts per week
- % of alerts followed by actual observed rain/wind
- Average lead time before event

---

## Roadmap & Future Improvements

This project is intentionally scoped as a local, single-location pipeline. The next iterations focus on improving signal quality, explainability, and practical AI-assisted analysis.

### 1. AI Explainability Assistant (Next Major Iteration)
Add an LLM-based assistant that helps interpret the pipeline outputs and explain forecast changes in human terms.

Example questions:
- “Why did the wind alert trigger today?”
- “Why were there so many alerts this morning?”
- “Why did it feel colder outside than expected?”
- “Are my current alert thresholds too sensitive?”

The assistant would analyze forecast snapshots, monitoring tables, alert logs, and morning brief outputs to generate concise explanations and support threshold tuning.

---

### 2. Forecast Change Detection
Detect and surface significant forecast changes compared to:
- previous forecast snapshots
- previous day conditions
- recent historical patterns

Example:
> “Temperature is expected to drop by 6°C compared to yesterday afternoon.”

This would improve decision awareness for clothing and outdoor planning.

---

### 3. Alert Evaluation Metrics
Introduce evaluation metrics to measure alert usefulness over time.

Examples:
- alerts per day / week
- lead time before event
- false positives vs missed signals
- forecast volatility

This would make it easier to tune the system based on observed alert behavior rather than intuition alone.

---

### 4. Data-Informed Threshold Tuning
Move from fixed thresholds toward more data-informed signal detection.

Examples:
- thresholds based on recent historical distributions
- percentile-based alerts
- season-aware weighting of wind / rain / temperature changes

This would improve the consistency of what counts as a “significant” weather change.

---

### 5. Configuration & Packaging Improvements
Improve maintainability by:
- centralizing configuration (location, thresholds, time windows)
- converting the repository into a proper Python package
- removing `sys.path` adjustments
- adding dependency management (`requirements.txt` or `pyproject.toml`)

---

### 6. Automated Logic Testing
Add validation for key business rules, including:
- unit tests for alert decision logic
- synthetic forecast datasets for integration testing
- validation tests for morning brief formatting

---

### 7. Optional Production Deployment
Replace the local macOS scheduler with a lightweight production setup:
- cloud scheduler (GitHub Actions, cron job, or lightweight VM)
- proper secrets management
- remote logging / monitoring

## Repository Structure

scripts/  
- `run_weather_pipeline.sh` — Main orchestrator script  

src/  
- ingest/ — API ingestion & raw loading  
- notify/ — Alerts, morning brief, Telegram integration  

sql/  
- models/ — Core, monitoring, alerts, brief  
- eda/ — Debugging & exploratory SQL  

data/  
- raw/ — Raw JSON snapshots  
- duckdb/weather.duckdb — Local database file  
- exports/logs/ — Pipeline logs  

docs/  
- Architecture, data model, monitoring, evaluation deep dives  

assets/  
- Architecture diagram and sample outputs


## Quickstart (Local)

Requirements:
- Python 3.10+
- DuckDB
- Telegram Bot token (optional, for notifications)

Run a full pipeline cycle:

bash scripts/run_weather_pipeline.sh

Run morning brief in dry mode:

python src/notify/print_morning_brief.py --dry-run
