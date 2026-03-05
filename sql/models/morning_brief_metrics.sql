-- morning_brief_metrics.sql
-- Stable dataset for daily morning summary

WITH latest_snapshot AS (
  SELECT
    location_name,
    MAX(snapshot_time_utc) AS snapshot_time_utc
  FROM snapshots_hourly
  GROUP BY 1
),

latest_data AS (
  SELECT s.*
  FROM snapshots_hourly s
  JOIN latest_snapshot l
    ON s.location_name = l.location_name
   AND s.snapshot_time_utc = l.snapshot_time_utc
),

today_date AS (
  SELECT
    location_name,
    MIN(forecast_date_local) AS today_date
  FROM latest_data
  GROUP BY 1
),

-- Today average
today_all AS (
  SELECT
    d.location_name,
    t.today_date,
    AVG(d.temperature_c) AS today_avg_temp
  FROM latest_data d
  JOIN today_date t
    ON d.location_name = t.location_name
   AND d.forecast_date_local = t.today_date
  WHERE d.forecast_hour_local BETWEEN 6 AND 23
  GROUP BY 1,2
),

-- Yesterday average (within same snapshot window)
yesterday_all AS (
  SELECT
    d.location_name,
    AVG(d.temperature_c) AS yday_avg_temp
  FROM latest_data d
  JOIN today_date t
    ON d.location_name = t.location_name
   AND d.forecast_date_local = t.today_date - INTERVAL 1 DAY
  WHERE d.forecast_hour_local BETWEEN 6 AND 23
  GROUP BY 1
),

-- Last 4 days average (excluding today)
last4days_avg AS (
  SELECT
    d.location_name,
    AVG(d.temperature_c) AS last4_avg_temp
  FROM latest_data d
  JOIN today_date t
    ON d.location_name = t.location_name
   AND d.forecast_date_local BETWEEN t.today_date - INTERVAL 4 DAY
                                   AND t.today_date - INTERVAL 1 DAY
  WHERE d.forecast_hour_local BETWEEN 6 AND 23
  GROUP BY 1
),

-- Daypart deltas (today vs yesterday)
daypart_deltas AS (
  SELECT
    t.location_name,
    t.daypart,
    t.avg_temp_c - y.avg_temp_c AS delta_temp
  FROM (
    SELECT
      d.location_name,
      CASE
        WHEN forecast_hour_local BETWEEN 6 AND 9  THEN 'morning'
        WHEN forecast_hour_local BETWEEN 10 AND 13 THEN 'noon'
        WHEN forecast_hour_local BETWEEN 14 AND 17 THEN 'afternoon'
        WHEN forecast_hour_local BETWEEN 18 AND 23 THEN 'evening'
      END AS daypart,
      AVG(temperature_c) AS avg_temp_c
    FROM latest_data d
    JOIN today_date t
      ON d.location_name = t.location_name
     AND d.forecast_date_local = t.today_date
    WHERE d.forecast_hour_local BETWEEN 6 AND 23
    GROUP BY 1,2
  ) t
  JOIN (
    SELECT
      d.location_name,
      CASE
        WHEN forecast_hour_local BETWEEN 6 AND 9  THEN 'morning'
        WHEN forecast_hour_local BETWEEN 10 AND 13 THEN 'noon'
        WHEN forecast_hour_local BETWEEN 14 AND 17 THEN 'afternoon'
        WHEN forecast_hour_local BETWEEN 18 AND 23 THEN 'evening'
      END AS daypart,
      AVG(temperature_c) AS avg_temp_c
    FROM latest_data d
    JOIN today_date t
      ON d.location_name = t.location_name
     AND d.forecast_date_local = t.today_date - INTERVAL 1 DAY
    WHERE d.forecast_hour_local BETWEEN 6 AND 23
    GROUP BY 1,2
  ) y
  ON t.location_name = y.location_name
 AND t.daypart = y.daypart
),

max_delta AS (
  SELECT
    location_name,
    MAX(ABS(delta_temp)) AS max_abs_delta
  FROM daypart_deltas
  GROUP BY 1
),

max_delta_label AS (
  SELECT
    d.location_name,
    d.daypart AS most_changed_daypart,
    d.delta_temp AS max_daypart_delta
  FROM daypart_deltas d
  JOIN max_delta m
    ON d.location_name = m.location_name
   AND ABS(d.delta_temp) = m.max_abs_delta
)

SELECT
  t.location_name,
  t.today_date,

  t.today_avg_temp,
  y.yday_avg_temp,
  t.today_avg_temp - y.yday_avg_temp AS delta_vs_yesterday,

  l.last4_avg_temp,
  t.today_avg_temp - l.last4_avg_temp AS delta_vs_last4days,

  m.most_changed_daypart,
  m.max_daypart_delta

FROM today_all t
LEFT JOIN yesterday_all y
  ON t.location_name = y.location_name
LEFT JOIN last4days_avg l
  ON t.location_name = l.location_name
LEFT JOIN max_delta_label m
  ON t.location_name = m.location_name;
