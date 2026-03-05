WITH today AS (
  SELECT *
  FROM (
    -- reuse your today logic
    WITH latest_snapshot AS (
      SELECT location_name, MAX(snapshot_time_utc) AS snapshot_time_utc
      FROM snapshots_hourly
      GROUP BY 1
    )
    SELECT
      s.location_name,
      s.forecast_date_local AS date_local,
      CASE
        WHEN forecast_hour_local BETWEEN 6 AND 9  THEN 'morning'
        WHEN forecast_hour_local BETWEEN 10 AND 13 THEN 'noon'
        WHEN forecast_hour_local BETWEEN 14 AND 17 THEN 'afternoon'
        WHEN forecast_hour_local BETWEEN 18 AND 23 THEN 'evening'
      END AS daypart,
      AVG(temperature_c)  AS avg_temp_c,
      AVG(feels_like_c)   AS avg_feels_like_c,
      AVG(wind_kmh)       AS avg_wind_kmh
    FROM snapshots_hourly s
    JOIN latest_snapshot l
      ON s.location_name = l.location_name
     AND s.snapshot_time_utc = l.snapshot_time_utc
    WHERE s.forecast_date_local = CURRENT_DATE
      AND s.forecast_hour_local BETWEEN 6 AND 23
    GROUP BY 1,2,3
  )
),

yesterday AS (
  SELECT *
  FROM (
    WITH latest_snapshot AS (
      SELECT location_name, MAX(snapshot_time_utc) AS snapshot_time_utc
      FROM snapshots_hourly
      GROUP BY 1
    )
    SELECT
      s.location_name,
      s.forecast_date_local AS date_local,
      CASE
        WHEN forecast_hour_local BETWEEN 6 AND 9  THEN 'morning'
        WHEN forecast_hour_local BETWEEN 10 AND 13 THEN 'noon'
        WHEN forecast_hour_local BETWEEN 14 AND 17 THEN 'afternoon'
        WHEN forecast_hour_local BETWEEN 18 AND 23 THEN 'evening'
      END AS daypart,
      AVG(temperature_c)  AS avg_temp_c,
      AVG(feels_like_c)   AS avg_feels_like_c,
      AVG(wind_kmh)       AS avg_wind_kmh
    FROM snapshots_hourly s
    JOIN latest_snapshot l
      ON s.location_name = l.location_name
     AND s.snapshot_time_utc = l.snapshot_time_utc
    WHERE s.forecast_date_local = CURRENT_DATE - INTERVAL 1 DAY
      AND s.forecast_hour_local BETWEEN 6 AND 23
    GROUP BY 1,2,3
  )
)

SELECT
  t.location_name,
  t.daypart,

  t.avg_temp_c AS today_temp,
  y.avg_temp_c AS yday_temp,
  t.avg_temp_c - y.avg_temp_c AS delta_temp,

  t.avg_wind_kmh AS today_wind,
  y.avg_wind_kmh AS yday_wind,
  t.avg_wind_kmh - y.avg_wind_kmh AS delta_wind

FROM today t
JOIN yesterday y
  ON t.location_name = y.location_name
 AND t.daypart = y.daypart
ORDER BY t.daypart;
