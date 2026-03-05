DROP TABLE IF EXISTS alert_rain_next6h_gated;

CREATE TABLE alert_rain_next6h_gated AS
WITH decision AS (
  SELECT *
  FROM alert_rain_next6h_decision
  LIMIT 1
),
last_sent AS (
  SELECT
    MAX(sent_time_utc) AS last_sent_time_utc
  FROM alert_log
  WHERE alert_type = 'rain_next6h'
),
cooldown AS (
  SELECT
    (SELECT last_sent_time_utc FROM last_sent) AS last_sent_time_utc,
    CASE
      WHEN (SELECT last_sent_time_utc FROM last_sent) IS NULL THEN FALSE
      WHEN now() < (SELECT last_sent_time_utc FROM last_sent) + INTERVAL '2 hours' THEN TRUE
      ELSE FALSE
    END AS in_cooldown
)
SELECT
  d.*,
  c.last_sent_time_utc,
  c.in_cooldown,
  CASE
    WHEN d.should_alert_rain_next6h = TRUE AND c.in_cooldown = FALSE THEN TRUE
    ELSE FALSE
  END AS should_send_after_gating
FROM decision d
CROSS JOIN cooldown c;
