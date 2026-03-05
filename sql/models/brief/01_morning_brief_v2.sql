-- morning_brief_v2 (Prague) - 1 row output
-- Computes summary for the NEXT 12 HOURS starting from "now" in Europe/Prague local time.
-- Uses the LATEST available snapshot in snapshots_hourly.

WITH params AS (
  SELECT
    'Prague'::VARCHAR AS location_name,
    date_trunc('hour', (now() AT TIME ZONE 'Europe/Prague')) AS now_local,
    date_trunc('hour', (now() AT TIME ZONE 'Europe/Prague')) + INTERVAL 12 HOUR AS until_local
),

latest_snapshot AS (
  SELECT
    sh.location_name,
    max(sh.snapshot_time_utc) AS snapshot_time_utc
  FROM snapshots_hourly sh
  JOIN params p ON p.location_name = sh.location_name
  GROUP BY 1
),

horizon AS (
  SELECT
    sh.*
  FROM snapshots_hourly sh
  JOIN latest_snapshot ls
    ON sh.location_name = ls.location_name
   AND sh.snapshot_time_utc = ls.snapshot_time_utc
  JOIN params p
    ON sh.location_name = p.location_name
   AND sh.forecast_time_local >= p.now_local
   AND sh.forecast_time_local <  p.until_local
),

agg AS (
  SELECT
    location_name,
    snapshot_time_utc,

    -- core metrics
    avg(temperature_c)  AS avg_temp_c,
    avg(feels_like_c)   AS avg_feels_like_c,
    avg(cloudcover_pct) AS avg_cloudcover_pct,

    -- flags / peaks
    max(coalesce(precipitation_mm, 0)) > 0 AS rain_possible,
    max(wind_kmh) AS max_wind_kmh,

    -- debug helpers
    min(forecast_time_local) AS window_start_local,
    max(forecast_time_local) AS window_end_local,
    count(*) AS n_hours
  FROM horizon
  GROUP BY 1,2
)

SELECT
  a.location_name,
  a.snapshot_time_utc,

  round(a.avg_temp_c, 1) AS avg_temp_c_12h,
  round(a.avg_feels_like_c, 1) AS avg_feels_like_c_12h,

  round(a.avg_cloudcover_pct, 0) AS avg_cloudcover_pct_12h,

  CASE
    WHEN a.avg_cloudcover_pct IS NULL THEN 'unknown'
    WHEN a.avg_cloudcover_pct <= 20 THEN 'clear'
    WHEN a.avg_cloudcover_pct <= 60 THEN 'partly cloudy'
    ELSE 'cloudy'
  END AS sky_text,

  a.rain_possible,
  round(a.max_wind_kmh, 0) AS max_wind_kmh_12h,

  a.window_start_local,
  a.window_end_local,
  a.n_hours

FROM agg a;