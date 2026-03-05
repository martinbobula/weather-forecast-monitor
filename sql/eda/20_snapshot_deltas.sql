WITH ranked AS (
  SELECT
    *,
    DENSE_RANK() OVER (
      PARTITION BY location_name
      ORDER BY snapshot_time_utc DESC
    ) AS snapshot_rank
  FROM snapshots_hourly
),

paired AS (
  SELECT
    curr.location_name,
    curr.forecast_time_local,

    curr.snapshot_time_utc AS curr_snapshot,
    prev.snapshot_time_utc AS prev_snapshot,

    curr.temperature_c - prev.temperature_c       AS delta_temp_c,
    curr.feels_like_c - prev.feels_like_c         AS delta_feels_like_c,
    curr.precipitation_mm - prev.precipitation_mm AS delta_precip_mm,
    curr.wind_kmh - prev.wind_kmh                 AS delta_wind_kmh

  FROM ranked curr
  JOIN ranked prev
    ON curr.location_name = prev.location_name
   AND curr.forecast_time_local = prev.forecast_time_local
   AND curr.snapshot_rank = 1
   AND prev.snapshot_rank = 2
)

SELECT *
FROM paired
ORDER BY forecast_time_local
LIMIT 20;