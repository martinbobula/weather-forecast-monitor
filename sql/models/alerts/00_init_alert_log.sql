CREATE TABLE IF NOT EXISTS alert_log (
  sent_time_utc TIMESTAMP,
  alert_type VARCHAR,
  snapshot_time_utc TIMESTAMP,
  message VARCHAR
);
