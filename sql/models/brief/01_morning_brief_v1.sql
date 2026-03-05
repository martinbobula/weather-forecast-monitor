DROP TABLE IF EXISTS morning_brief_v1;

CREATE TABLE morning_brief_v1 AS
WITH ctx AS (
  SELECT
    (now() AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Prague')::DATE AS today_local,
    (now() AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Prague') AS now_local
),
latest_snap AS (
  SELECT snapshot_time_utc
  FROM snapshot_registry
  WHERE location_name = 'Prague'
  ORDER BY snapshot_time_utc DESC
  LIMIT 1
),
next_hours AS (
  SELECT
    h.*
  FROM snapshots_hourly h
  CROSS JOIN ctx c
  WHERE h.location_name = 'Prague'
    AND h.snapshot_time_utc = (SELECT snapshot_time_utc FROM latest_snap)
    AND h.forecast_time_local >= c.now_local
    AND h.forecast_time_local <  c.now_local + INTERVAL '12 hours'
),
headline AS (
  SELECT
    (SELECT today_local FROM ctx) AS today_local_date,
    ROUND(AVG(temperature_c), 1) AS avg_temp_next12h,
    ROUND(AVG(feels_like_c), 1) AS avg_feels_next12h,
    MAX(CASE WHEN precipitation_mm > 0 THEN 1 ELSE 0 END) AS any_rain_next12h,
    ROUND(MAX(wind_kmh), 0) AS max_wind_next12h
  FROM next_hours
)
SELECT * FROM headline;