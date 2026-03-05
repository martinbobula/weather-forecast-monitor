CREATE TABLE IF NOT EXISTS snapshot_registry (
  location_name VARCHAR,
  snapshot_time_utc TIMESTAMP,
  raw_file VARCHAR PRIMARY KEY,
  content_hash VARCHAR,
  inserted_at_utc TIMESTAMP DEFAULT NOW()
);
