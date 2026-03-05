SELECT
  snapshot_time_utc,
  MIN(cloudcover_pct) AS min_cloud,
  MAX(cloudcover_pct) AS max_cloud
FROM snapshots_hourly
WHERE location_name = 'Prague'
GROUP BY 1
ORDER BY snapshot_time_utc DESC
LIMIT 3;