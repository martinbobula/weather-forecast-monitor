SELECT
  location_name,
  snapshot_time_utc,
  raw_file
FROM raw_snapshots
WHERE location_name = 'Prague'
ORDER BY snapshot_time_utc DESC
LIMIT 5;
