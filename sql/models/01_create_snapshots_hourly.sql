-- 01_create_snapshots_hourly.sql
-- Purpose: Normalize raw Open-Meteo hourly arrays into a flat analytics table
-- Grain: 1 row = location_name × snapshot_time_utc × forecast_time_local

CREATE OR REPLACE TABLE snapshots_hourly AS
WITH base AS (
  SELECT
    location_name,
    snapshot_time_utc,
    timezone,

    -- Extract JSON arrays and cast them into DuckDB list types
    json_extract(payload_json, '$.hourly.time')::VARCHAR[]                    AS t_time,
    json_extract(payload_json, '$.hourly.temperature_2m')::DOUBLE[]           AS t_temp_c,
    json_extract(payload_json, '$.hourly.apparent_temperature')::DOUBLE[]     AS t_feels_like_c,
    json_extract(payload_json, '$.hourly.precipitation')::DOUBLE[]            AS t_precip_mm,
    json_extract(payload_json, '$.hourly.windspeed_10m')::DOUBLE[]            AS t_wind_kmh

  FROM raw_snapshots_deduped
),
exploded AS (
  SELECT
    b.location_name,
    b.snapshot_time_utc,
    b.timezone,

    -- DuckDB lists are 1-indexed when accessed like list[i]
    i AS idx,

    -- Keep local forecast time as timestamp (Open-Meteo returned local because we requested timezone=Europe/Prague)
    CAST(b.t_time[i] AS TIMESTAMP) AS forecast_time_local,

    b.t_temp_c[i]        AS temperature_c,
    b.t_feels_like_c[i]  AS feels_like_c,
    b.t_precip_mm[i]     AS precipitation_mm,
    b.t_wind_kmh[i]      AS wind_kmh

  FROM base b
  -- generate indices 1..N based on the length of the time array
  CROSS JOIN range(1, array_length(b.t_time) + 1) AS r(i)
)
SELECT
  location_name,
  snapshot_time_utc,
  timezone,
  idx,
  forecast_time_local,
  CAST(date_trunc('day', forecast_time_local) AS DATE) AS forecast_date_local,
  EXTRACT('hour' FROM forecast_time_local) AS forecast_hour_local,

  temperature_c,
  feels_like_c,
  precipitation_mm,
  wind_kmh

FROM exploded;
