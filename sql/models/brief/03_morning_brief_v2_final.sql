-- Morning brief v2 FINAL (1 row)
-- Includes: 12h averages + sky_text + rain flag + max wind + compact dayparts line

WITH params AS (
  SELECT
    'Prague'::VARCHAR AS location_name,
    date_trunc('hour', (now() AT TIME ZONE 'Europe/Prague')) AS now_local,
    date_trunc('hour', (now() AT TIME ZONE 'Europe/Prague')) + INTERVAL 12 HOUR AS until_local,

    date_trunc('day', (now() AT TIME ZONE 'Europe/Prague')) + INTERVAL 6 HOUR AS today_start_local,
    date_trunc('day', (now() AT TIME ZONE 'Europe/Prague')) + INTERVAL 24 HOUR AS today_end_local
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

-- Main 12h aggregates
agg AS (
  SELECT
    location_name,
    snapshot_time_utc,

    avg(temperature_c)  AS avg_temp_c,
    avg(feels_like_c)   AS avg_feels_like_c,
    avg(cloudcover_pct) AS avg_cloudcover_pct,

    max(coalesce(precipitation_mm, 0)) > 0 AS rain_possible,
    max(wind_kmh) AS max_wind_kmh,

    min(forecast_time_local) AS window_start_local,
    max(forecast_time_local) AS window_end_local,
    count(*) AS n_hours
  FROM horizon
  GROUP BY 1,2
),

-- Dayparts (same 12h window)
labeled AS (
  SELECT
    sh.location_name,
    sh.snapshot_time_utc,
    sh.forecast_time_local,
    sh.temperature_c,
    coalesce(sh.precipitation_mm, 0) AS precipitation_mm,
    extract('hour' FROM sh.forecast_time_local) AS hour_local,
    CASE
      WHEN extract('hour' FROM sh.forecast_time_local) BETWEEN  6 AND 11 THEN 'morning'
      WHEN extract('hour' FROM sh.forecast_time_local) BETWEEN 12 AND 14 THEN 'noon'
      WHEN extract('hour' FROM sh.forecast_time_local) BETWEEN 15 AND 18 THEN 'afternoon'
      WHEN extract('hour' FROM sh.forecast_time_local) BETWEEN 19 AND 23 THEN 'evening'
      ELSE NULL
    END AS daypart
  FROM snapshots_hourly sh
  JOIN latest_snapshot ls
    ON sh.location_name = ls.location_name
   AND sh.snapshot_time_utc = ls.snapshot_time_utc
  JOIN params p
    ON sh.location_name = p.location_name
   AND sh.forecast_time_local >= p.today_start_local
   AND sh.forecast_time_local <  p.today_end_local
),

daypart_agg AS (
  SELECT
    location_name,
    snapshot_time_utc,
    daypart,
    avg(temperature_c) AS avg_temp_c,
    max(precipitation_mm) > 0 AS rain_possible
  FROM labeled
  WHERE daypart IS NOT NULL
  GROUP BY 1,2,3
),

daypart_parts AS (
  SELECT
    location_name,
    snapshot_time_utc,
    CASE daypart
      WHEN 'morning' THEN 1
      WHEN 'noon' THEN 2
      WHEN 'afternoon' THEN 3
      WHEN 'evening' THEN 4
      ELSE 9
    END AS sort_key,
    daypart,
    cast(cast(round(avg_temp_c, 0) AS INT) AS VARCHAR) AS temp_int_text,
    rain_possible
  FROM daypart_agg
),

dayparts_meta AS (
  SELECT
    location_name,
    snapshot_time_utc,
    sum(CASE WHEN rain_possible THEN 1 ELSE 0 END) AS rainy_parts,
    count(*) AS total_parts
  FROM daypart_parts
  GROUP BY 1,2
),

dayparts_line AS (
  SELECT
    p.location_name,
    p.snapshot_time_utc,
    string_agg(
      p.daypart || ' ' || p.temp_int_text || '°C'
      || CASE
           WHEN m.rainy_parts = m.total_parts THEN ''              -- rain everywhere -> don't spam tags
           WHEN p.rain_possible THEN ' (rain)'                     -- rain only in some parts -> tag those
           ELSE ''
         END,
      ' • ' ORDER BY p.sort_key
    ) AS dayparts_line
  FROM daypart_parts p
  JOIN dayparts_meta m
    ON p.location_name = m.location_name
   AND p.snapshot_time_utc = m.snapshot_time_utc
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

  d.dayparts_line,

  a.window_start_local,
  a.window_end_local,
  a.n_hours

FROM agg a
LEFT JOIN dayparts_line d
  ON a.location_name = d.location_name
 AND a.snapshot_time_utc = d.snapshot_time_utc;