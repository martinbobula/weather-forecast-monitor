-- Dayparts summary (next 12h) for latest snapshot
-- Output: 1 row with a single string "morning 5°C • noon 6°C • afternoon 7°C • evening 6°C"
-- Only includes dayparts that appear in the next 12h window.

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
    sh.location_name,
    sh.snapshot_time_utc,
    sh.forecast_time_local,
    sh.temperature_c,
    coalesce(sh.precipitation_mm, 0) AS precipitation_mm
  FROM snapshots_hourly sh
  JOIN latest_snapshot ls
    ON sh.location_name = ls.location_name
   AND sh.snapshot_time_utc = ls.snapshot_time_utc
  JOIN params p
    ON sh.location_name = p.location_name
   AND sh.forecast_time_local >= p.now_local
   AND sh.forecast_time_local <  p.until_local
),

labeled AS (
  SELECT
    *,
    extract('hour' FROM forecast_time_local) AS hour_local,
    CASE
      WHEN extract('hour' FROM forecast_time_local) BETWEEN  6 AND 11 THEN 'morning'
      WHEN extract('hour' FROM forecast_time_local) BETWEEN 12 AND 14 THEN 'noon'
      WHEN extract('hour' FROM forecast_time_local) BETWEEN 15 AND 18 THEN 'afternoon'
      WHEN extract('hour' FROM forecast_time_local) BETWEEN 19 AND 23 THEN 'evening'
      ELSE NULL
    END AS daypart
  FROM horizon
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

ordered AS (
  SELECT
    *,
    CASE daypart
      WHEN 'morning' THEN 1
      WHEN 'noon' THEN 2
      WHEN 'afternoon' THEN 3
      WHEN 'evening' THEN 4
      ELSE 9
    END AS sort_key
  FROM daypart_agg
),

parts AS (
  SELECT
    location_name,
    snapshot_time_utc,
    sort_key,
    daypart,
    -- example: "afternoon 6°C" or "afternoon 6°C (rain)"
    daypart || ' ' || cast(cast(round(avg_temp_c, 0) AS INT) AS VARCHAR) || '°C'
  || CASE WHEN rain_possible THEN ' (rain)' ELSE '' END AS part_text
  FROM ordered
)

SELECT
  location_name,
  snapshot_time_utc,
  string_agg(part_text, ' • ' ORDER BY sort_key) AS dayparts_line
FROM parts
GROUP BY 1,2;