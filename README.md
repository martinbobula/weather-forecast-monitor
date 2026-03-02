# Weather Forecast Monitor (Prague)

A local, SQL-first weather pipeline that turns a public forecast API into **decision-support alerts** and a daily **morning brief** — designed for a real use case (me / my girlfriend / my friends in Prague) where the goal is to **avoid being surprised** by meaningful weather changes.

This repository is intentionally **simple but trustworthy**: it focuses on clear data layers, transparent business rules in SQL, and reliability patterns (idempotency, monitoring, cooldown gating) rather than UI, ML, or scale. It’s a portfolio project built to practice real-world pipeline thinking and communicate it clearly to non-engineering stakeholders.

---

## Executive summary

**Problem (user + decision):**
We check the weather to decide what to wear, whether to bring a rain jacket, and whether wind/rain will disrupt plans. The pain is not “lack of information” — it’s **noise, last-minute surprises and not checking weather by myself whenever it is truly needed**. This project converts forecasts into **actionable signals**:
- “Rain became likely within the next 6 hours (new information).”
- “Wind risk spiked compared to the previous forecast.”
- “Morning brief: what the next 12 hours look like, including dayparts (morning/noon/afternoon/evening).”
- 
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
- Alerts are **rare enough to be trusted**, but fast enough to prevent surprises
- Alerts trigger on **meaningful changes** (not repeated noise)
- Pipeline runs are **repeatable and debuggable** (logs + monitoring table)
- Data is layered and auditable: raw → modeled → decisions → notifications

**Non-goals (intentional):**
- No UI or mobile app
- No ML forecasting (uses Open-Meteo as the forecast provider)
- No multi-city scale (single-location template first)
- No cloud deployment in this repo (see roadmap for productionization path)

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

> ![Architecture diagram](assets/architecture.png)
