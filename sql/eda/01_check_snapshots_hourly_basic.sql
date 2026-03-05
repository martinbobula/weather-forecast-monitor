SELECT
  location_name,
  COUNT(*) AS n_rows,
  COUNT(DISTINCT snapshot_time_utc) AS n_snapshots,
  MIN(forecast_time_local) AS first_forecast_time_local,
  MAX(forecast_time_local) AS last_forecast_time_local
FROM snapshots_hourly
GROUP BY 1
ORDER BY 1;
