-- Rain alert decision: rain appears in next 6 hours (change-aware)

DROP TABLE IF EXISTS alert_rain_next6h_decision;

CREATE TABLE alert_rain_next6h_decision AS
WITH run_ctx AS (
  SELECT
    now() AS run_time_utc,
    (now() AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Prague') AS run_time_local
),

latest_two AS (
  SELECT
    snapshot_time_utc,
    ROW_NUMBER() OVER (ORDER BY snapshot_time_utc DESC) AS rn
  FROM snapshot_registry
  WHERE location_name = 'Prague'
),

snapshots_to_check AS (
  SELECT snapshot_time_utc, rn
  FROM latest_two
  WHERE rn <= 2
),

rain_flag AS (
  SELECT
    s2c.rn,
    s2c.snapshot_time_utc,
    MAX(CASE WHEN h.precipitation_mm > 0 THEN 1 ELSE 0 END) AS rain_next6h
  FROM snapshots_to_check s2c
  JOIN snapshots_hourly h
    ON h.location_name = 'Prague'
   AND h.snapshot_time_utc = s2c.snapshot_time_utc
  CROSS JOIN run_ctx c
  WHERE h.forecast_time_local >= c.run_time_local
    AND h.forecast_time_local <  c.run_time_local + INTERVAL '6 hours'
  GROUP BY 1,2
),

rain_pivot AS (
  SELECT
    (SELECT run_time_utc FROM run_ctx) AS run_time_utc,
    MAX(CASE WHEN rn = 1 THEN snapshot_time_utc END) AS current_snapshot_utc,
    MAX(CASE WHEN rn = 2 THEN snapshot_time_utc END) AS prev_snapshot_utc,
    MAX(CASE WHEN rn = 1 THEN rain_next6h END) AS current_rain_next6h,
    MAX(CASE WHEN rn = 2 THEN rain_next6h END) AS prev_rain_next6h
  FROM rain_flag
)

SELECT
  run_time_utc,
  current_snapshot_utc,
  prev_snapshot_utc,
  current_rain_next6h,
  prev_rain_next6h,
  CASE
  WHEN prev_rain_next6h IS NOT NULL
   AND current_rain_next6h = 1
   AND prev_rain_next6h = 0
  THEN TRUE
  ELSE FALSE
END AS should_alert_rain_next6h

FROM rain_pivot;
