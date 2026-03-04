# Data Model

This project follows a “raw → normalized → decision outputs” structure.

## Bronze layer (raw storage)
### `raw_snapshots`
Purpose: store the raw API payload (JSON) with minimal transformation.

Key columns (conceptual):
- snapshot_time_utc
- location_name (Prague)
- lat, lon, timezone
- payload_json (raw Open-Meteo response)
- source, endpoint
- raw_file (points to JSON on disk)

### `snapshot_registry`
Purpose: ingestion ledger + change tracking.

Key columns (conceptual):
- location_name
- snapshot_time_utc
- raw_file (primary identifier in current implementation)
- content_hash (sha256 of payload)
- inserted_at_utc

Used for:
- monitoring “did we ingest hourly today?”
- detecting whether forecast content changed between snapshots

## Silver layer (normalized)
### `snapshots_hourly`
Purpose: row-based hourly forecast table flattened from JSON arrays.

Grain:
- one row per (snapshot_time_utc, location_name, forecast_time_local)

Example columns:
- forecast_time_local, forecast_date_local, forecast_hour_local
- temperature_c, feels_like_c
- precipitation_mm
- wind_kmh
- cloudcover_pct

This is the main table used by monitoring, alerts, and morning brief.

## Gold layer (decision outputs)
### `monitoring_snapshot_health`
Purpose: “is the system healthy today?”

Contains per-run metrics such as:
- run_time_utc
- snapshots_today
- last_snapshot_local
- change_rate_pct_today
- missing_hour_count_06_19
- missing_hours_list

### Alert tables
Computed from latest snapshots:
- `alert_rain_next6h_decision` → `alert_rain_next6h_gated`
- `alert_wind_next6h_decision` → `alert_wind_next6h_gated`

### `alert_log`
Purpose: record alert sends for auditability + cooldown gating.

### `brief_log`
Purpose: record morning brief sends and enforce “once per day.”

## Notes / current limitations
- Many SQL models rebuild tables using DROP/CREATE (PoC simplicity).
- Single-location design is intentional for scope; multi-city would require parameterization.
