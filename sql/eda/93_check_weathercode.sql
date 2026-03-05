SELECT
  json_extract(payload_json, '$.hourly.weathercode') IS NOT NULL AS has_hourly_weathercode
FROM raw_snapshots
WHERE location_name = 'Prague'
ORDER BY snapshot_time_utc DESC
LIMIT 1;
