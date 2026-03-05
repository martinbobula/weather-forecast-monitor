SELECT
  json_extract(payload_json, '$.hourly.cloudcover') IS NOT NULL AS has_cloudcover
FROM raw_snapshots
WHERE location_name = 'Prague'
ORDER BY snapshot_time_utc DESC
LIMIT 1;
