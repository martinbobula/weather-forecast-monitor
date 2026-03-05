SELECT
  location_name,
  COUNT(*) AS n_files_loaded,
  MIN(snapshot_time_utc) AS first_snapshot,
  MAX(snapshot_time_utc) AS last_snapshot
FROM snapshot_registry
GROUP BY 1;
