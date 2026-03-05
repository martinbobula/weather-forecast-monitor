-- Reset table (safe, it's only monitoring)
DROP TABLE IF EXISTS monitoring_snapshot_health;

CREATE TABLE monitoring_snapshot_health (
  run_time_utc TIMESTAMP,
  location_name VARCHAR,
  today_local_date DATE,
  snapshots_today BIGINT,
  last_snapshot_local TIMESTAMP,
  change_rate_pct_today DOUBLE,
  missing_hour_count_06_19 BIGINT,
  missing_hours_list VARCHAR
);

WITH params AS (
  SELECT
    'Prague'::VARCHAR AS location_name,
    current_date AS today_local
),
today_snaps AS (
  SELECT
    r.location_name,
    r.snapshot_time_utc,
    r.content_hash,
    (r.snapshot_time_utc AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Prague') AS snapshot_time_local,
    date_trunc('hour', (r.snapshot_time_utc AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Prague')) AS snapshot_hour_local
  FROM snapshot_registry r
  JOIN params p ON p.location_name = r.location_name
  WHERE (r.snapshot_time_utc AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Prague')::DATE = (SELECT today_local FROM params)
),
dedup_hours AS (
  -- if multiple snapshots in one hour, treat it as "hour present"
  SELECT
    snapshot_hour_local,
    min(content_hash) AS content_hash
  FROM today_snaps
  GROUP BY 1
),
hours_expected AS (
  -- expected hours today: 06:00 to 19:00 local time
  SELECT
    (today_local::TIMESTAMP + (h || ' hours')::INTERVAL) AS expected_hour_local
  FROM params
  CROSS JOIN generate_series(6, 19) AS t(h)
),
missing_hours AS (
  SELECT e.expected_hour_local
  FROM hours_expected e
  LEFT JOIN dedup_hours d
    ON d.snapshot_hour_local = e.expected_hour_local
  WHERE d.snapshot_hour_local IS NULL
),
hash_changes AS (
  SELECT
    snapshot_hour_local,
    content_hash,
    CASE
      WHEN lag(content_hash) OVER (ORDER BY snapshot_hour_local) IS NULL THEN NULL
      WHEN content_hash <> lag(content_hash) OVER (ORDER BY snapshot_hour_local) THEN 1
      ELSE 0
    END AS changed_vs_prev
  FROM dedup_hours
)

INSERT INTO monitoring_snapshot_health
SELECT
  now() AS run_time_utc,
  (SELECT location_name FROM params) AS location_name,
  (SELECT today_local FROM params) AS today_local_date,
  (SELECT count(*) FROM today_snaps) AS snapshots_today,
  (SELECT max(snapshot_time_local) FROM today_snaps) AS last_snapshot_local,
  (SELECT round(100.0 * avg(changed_vs_prev)::DOUBLE, 1)
   FROM hash_changes
   WHERE changed_vs_prev IS NOT NULL) AS change_rate_pct_today,
  (SELECT count(*) FROM missing_hours) AS missing_hour_count_06_19,
  (SELECT string_agg(strftime(expected_hour_local, '%H:%M'), ', ') FROM missing_hours) AS missing_hours_list;
