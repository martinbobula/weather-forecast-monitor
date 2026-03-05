-- Purpose:
-- Deduplicate raw snapshots so downstream analytics sees each raw file once

CREATE OR REPLACE VIEW raw_snapshots_deduped AS
SELECT
  snapshot_time_utc,
  location_name,
  latitude,
  longitude,
  timezone,
  payload_json,
  source,
  endpoint,
  raw_file
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY raw_file
      ORDER BY snapshot_time_utc
    ) AS rn
  FROM raw_snapshots
)
WHERE rn = 1;
