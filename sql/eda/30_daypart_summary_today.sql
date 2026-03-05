-- 30_daypart_summary_today.sql
-- Purpose: Create daypart-level aggregates for TODAY from the latest snapshot

WITH latest_snapshot AS (
  SELECT
    location_name,
    MAX(snapshot_time_utc) AS snapshot_time_utc
  FROM snapshots_hourly
  GROUP BY 1
),

today_hours AS (
  SELECT
    s.location_name,
    s.snapshot_time_utc,
    s.forecast_date_local,
    s.forecast_hour_local,
    s.temperature_c,
    s.feels_like_c,
    s.wind_kmh,
    s.precipitation_mm
  FROM snapshots_hourly s
  JOIN latest_snapshot l
    ON s.location_name = l.location_name
   AND s.snapshot_time_utc = l.snapshot_time_utc
  WHERE s.forecast_date_local = CURRENT_DATE
    AND s.forecast_hour_local BETWEEN 6 AND 23
),

labeled AS (
  SELECT
    *,
    CASE
      WHEN forecast_hour_local BETWEEN 6 AND 9  THEN 'morning'
      WHEN forecast_hour_local BETWEEN 10 AND 14 THEN 'noon'
      WHEN forecast_hour_local BETWEEN 14 AND 18 THEN 'afternoon'
      WHEN forecast_hour_local BETWEEN 19 AND 23 THEN 'evening'
      ELSE 'other'
    END AS daypart
  FROM today_hours
)

SELECT
  location_name,
  forecast_date_local AS date_local,
  daypart,

  AVG(temperature_c)  AS avg_temp_c,
  AVG(feels_like_c)   AS avg_feels_like_c,
  AVG(wind_kmh)       AS avg_wind_kmh,

  SUM(precipitation_mm) AS total_precip_mm,
  SUM(CASE WHEN precipitation_mm > 0 THEN 1 ELSE 0 END) AS precip_hours

FROM labeled
GROUP BY 1,2,3
ORDER BY daypart;
