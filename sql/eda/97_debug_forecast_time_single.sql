WITH latest AS (
  SELECT snapshot_time_utc
  FROM snapshot_registry
  WHERE location_name = 'Prague'
  ORDER BY snapshot_time_utc DESC
  LIMIT 1
),
stats AS (
  SELECT
    (SELECT snapshot_time_utc FROM latest) AS latest_snapshot_utc,
    COUNT(*) AS rows_in_snapshots_hourly_for_latest,
    MIN(forecast_time_local) AS min_forecast_time_local,
    MAX(forecast_time_local) AS max_forecast_time_local,
    typeof(MIN(forecast_time_local)) AS forecast_time_local_type
  FROM snapshots_hourly
  WHERE location_name = 'Prague'
    AND snapshot_time_utc = (SELECT snapshot_time_utc FROM latest)
),
sample AS (
  SELECT
    (SELECT snapshot_time_utc FROM latest) AS latest_snapshot_utc,
    forecast_time_local,
    typeof(forecast_time_local) AS forecast_time_local_type,
    precipitation_mm
  FROM snapshots_hourly
  WHERE location_name = 'Prague'
    AND snapshot_time_utc = (SELECT snapshot_time_utc FROM latest)
  ORDER BY forecast_time_local
  LIMIT 5
)
SELECT
  'STATS' AS section,
  CAST(latest_snapshot_utc AS VARCHAR) AS latest_snapshot_utc,
  CAST(rows_in_snapshots_hourly_for_latest AS VARCHAR) AS a,
  CAST(min_forecast_time_local AS VARCHAR) AS b,
  CAST(max_forecast_time_local AS VARCHAR) AS c,
  forecast_time_local_type AS d
FROM stats

UNION ALL

SELECT
  'SAMPLE' AS section,
  CAST(latest_snapshot_utc AS VARCHAR) AS latest_snapshot_utc,
  CAST(forecast_time_local AS VARCHAR) AS a,
  forecast_time_local_type AS b,
  CAST(precipitation_mm AS VARCHAR) AS c,
  '' AS d
FROM sample;
