SELECT
  location_name,
  snapshot_time_utc,
  forecast_time_local,
  COUNT(*) AS c,
  MIN(idx) AS min_idx,
  MAX(idx) AS max_idx
FROM snapshots_hourly
GROUP BY 1,2,3
HAVING COUNT(*) > 1
ORDER BY snapshot_time_utc DESC, forecast_time_local
LIMIT 20;
