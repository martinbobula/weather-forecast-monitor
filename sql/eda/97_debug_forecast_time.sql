-- 1) show latest snapshot time from registry
SELECT snapshot_time_utc
FROM snapshot_registry
WHERE location_name = 'Prague'
ORDER BY snapshot_time_utc DESC
LIMIT 3;

-- 2) show a few rows from snapshots_hourly for the latest snapshot
SELECT
  location_name,
  snapshot_time_utc,
  forecast_time_local,
  typeof(forecast_time_local) AS forecast_time_local_type,
  precipitation_mm
FROM snapshots_hourly
WHERE location_name = 'Prague'
  AND snapshot_time_utc = (
    SELECT snapshot_time_utc
    FROM snapshot_registry
    WHERE location_name = 'Prague'
    ORDER BY snapshot_time_utc DESC
    LIMIT 1
  )
LIMIT 5;
