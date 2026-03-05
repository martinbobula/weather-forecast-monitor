-- Build/refresh snapshots_hourly from raw_snapshots (Open-Meteo payload_json)
-- Compatible approach: use json_extract + array index paths.

DROP TABLE IF EXISTS snapshots_hourly;

CREATE TABLE snapshots_hourly AS
WITH base AS (
  SELECT
    location_name,
    snapshot_time_utc,
    payload_json
  FROM raw_snapshots
),

hourly AS (
  SELECT
    location_name,
    snapshot_time_utc,
    json_extract(payload_json, '$.hourly.time') AS j_time,
    json_extract(payload_json, '$.hourly.temperature_2m') AS j_temp,
    json_extract(payload_json, '$.hourly.apparent_temperature') AS j_feels,
    json_extract(payload_json, '$.hourly.precipitation') AS j_precip,
    json_extract(payload_json, '$.hourly.windspeed_10m') AS j_wind,
    json_extract(payload_json, '$.hourly.cloudcover') AS j_cloud
  FROM base
),

exploded AS (
  SELECT
    location_name,
    snapshot_time_utc,
    idx,

    json_extract_string(j_time,  '$[' || CAST(idx AS VARCHAR) || ']') AS forecast_time_str,

    CAST(json_extract(j_temp,   '$[' || CAST(idx AS VARCHAR) || ']') AS DOUBLE) AS temperature_c,
    CAST(json_extract(j_feels,  '$[' || CAST(idx AS VARCHAR) || ']') AS DOUBLE) AS feels_like_c,
    CAST(json_extract(j_precip, '$[' || CAST(idx AS VARCHAR) || ']') AS DOUBLE) AS precipitation_mm,
    CAST(json_extract(j_wind,   '$[' || CAST(idx AS VARCHAR) || ']') AS DOUBLE) AS wind_kmh,
    CAST(json_extract(j_cloud,   '$[' || CAST(idx AS VARCHAR) || ']') AS DOUBLE) AS cloudcover_pct
  FROM hourly
  CROSS JOIN generate_series(
    CAST(0 AS BIGINT),
    CAST(json_array_length(j_time) - 1 AS BIGINT)
  ) AS t(idx)
)

SELECT
  location_name,
  snapshot_time_utc,
  CAST(forecast_time_str AS TIMESTAMP) AS forecast_time_local,
  temperature_c,
  feels_like_c,
  precipitation_mm,
  wind_kmh,
  cloudcover_pct,
  CAST(forecast_time_str AS DATE) AS forecast_date_local,
  EXTRACT('hour' FROM CAST(forecast_time_str AS TIMESTAMP)) AS forecast_hour_local
FROM exploded;
