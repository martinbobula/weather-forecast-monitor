SELECT snapshot_time_utc, COUNT(*) AS rows
FROM snapshots_hourly
WHERE location_name = 'Prague'
GROUP BY 1
ORDER BY snapshot_time_utc DESC;
