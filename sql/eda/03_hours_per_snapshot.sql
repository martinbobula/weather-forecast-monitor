SELECT
  location_name,
  snapshot_time_utc,
  COUNT(*) AS n_hours
FROM snapshots_hourly
GROUP BY 1,2
ORDER BY snapshot_time_utc DESC
LIMIT 20;
