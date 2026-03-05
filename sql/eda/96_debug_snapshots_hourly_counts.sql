-- 1) Total rows in snapshots_hourly
SELECT COUNT(*) AS total_rows
FROM snapshots_hourly;

-- 2) Latest snapshot_time_utc present in snapshots_hourly
SELECT snapshot_time_utc, COUNT(*) AS rows
FROM snapshots_hourly
WHERE location_name = 'Prague'
GROUP BY 1
ORDER BY snapshot_time_utc DESC
LIMIT 5;

-- 3) Latest snapshot from registry (for comparison)
SELECT snapshot_time_utc
FROM snapshot_registry
WHERE location_name = 'Prague'
ORDER BY snapshot_time_utc DESC
LIMIT 5;
