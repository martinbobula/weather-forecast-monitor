SELECT
  location_name,

  -- temperature
  MIN(temperature_c) AS temp_min,
  quantile_cont(temperature_c, 0.05) AS temp_p05,
  quantile_cont(temperature_c, 0.50) AS temp_p50,
  quantile_cont(temperature_c, 0.95) AS temp_p95,
  MAX(temperature_c) AS temp_max,
  AVG(CASE WHEN temperature_c IS NULL THEN 1 ELSE 0 END) AS temp_null_rate,

  -- feels like
  MIN(feels_like_c) AS feels_min,
  quantile_cont(feels_like_c, 0.50) AS feels_p50,
  MAX(feels_like_c) AS feels_max,
  AVG(CASE WHEN feels_like_c IS NULL THEN 1 ELSE 0 END) AS feels_null_rate,

  -- precipitation
  MIN(precipitation_mm) AS precip_min,
  quantile_cont(precipitation_mm, 0.50) AS precip_p50,
  quantile_cont(precipitation_mm, 0.95) AS precip_p95,
  MAX(precipitation_mm) AS precip_max,
  AVG(CASE WHEN precipitation_mm = 0 THEN 1 ELSE 0 END) AS precip_zero_rate,
  AVG(CASE WHEN precipitation_mm IS NULL THEN 1 ELSE 0 END) AS precip_null_rate,

  -- wind
  MIN(wind_kmh) AS wind_min,
  quantile_cont(wind_kmh, 0.50) AS wind_p50,
  quantile_cont(wind_kmh, 0.95) AS wind_p95,
  MAX(wind_kmh) AS wind_max,
  AVG(CASE WHEN wind_kmh IS NULL THEN 1 ELSE 0 END) AS wind_null_rate

FROM snapshots_hourly
GROUP BY 1;
