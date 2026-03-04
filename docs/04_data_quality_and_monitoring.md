# Data Quality and Monitoring

This project treats “quality” as: **fresh, complete, non-duplicated, and explainable**.

## Idempotency (duplicate prevention)
Raw loading is designed to be re-runnable:
- each raw file is loaded at most once into `raw_snapshots`
- `snapshot_registry` records a content hash for change tracking

Why this matters:
- schedulers can trigger duplicate runs
- debugging often involves rerunning steps
- duplication breaks monitoring and alerting logic

## Monitoring model: `monitoring_snapshot_health`
The monitoring SQL produces a simple daily health record for Prague.

It checks:
1. **Freshness**
   - last snapshot local time (did we ingest recently?)

2. **Completeness between 06:00–19:00**
   - expected hours are generated
   - missing hours are listed

3. **Forecast volatility**
   - compares hourly content hash changes between snapshots
   - reports a “change rate %” signal

Why these signals are useful:
- if missing hours spike → scheduler issues or ingestion failures
- if change rate is always 0% → ingestion may be stuck
- if change rate is very high → upstream instability or modeling issues

## Logging
- Pipeline runs write logs to `data/exports/logs/`
- Logs include the ordered steps and Python/SQL output

This supports:
- debugging failures
- verifying gating behavior (time window, dry-run, once-per-day)

## Known gaps (planned improvements)
- No automated tests yet (validated through SQL EDA and manual inspection)
- No centralized run metadata table (an `etl_runs` table exists as a placeholder)
- No alert evaluation metrics captured automatically (planned)
