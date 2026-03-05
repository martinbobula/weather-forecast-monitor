SELECT
  location_name,
  COUNT(*) AS n_snapshots,
  MIN(snapshot_time_utc) AS first_snapshot_utc,
  MAX(snapshot_time_utc) AS last_snapshot_utc
FROM raw_snapshots
GROUP BY 1
ORDER BY 1;
