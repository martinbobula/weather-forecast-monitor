SELECT COUNT(*) AS duplicate_keys
FROM (
  SELECT
    location_name,
    snapshot_time_utc,
    forecast_time_local,
    COUNT(*) AS c
  FROM snapshots_hourly
  GROUP BY 1,2,3
  HAVING COUNT(*) > 1
);
