# Alerting and Evaluation

## Alert philosophy
The system aims to send alerts that are:
- actionable (in the next 6 hours)
- meaningful (new information)
- non-spammy (cooldown gated)

## Rain alert (next 6 hours)
### Decision logic (change-aware)
Simplified:
- look at the two most recent snapshots
- compute “is there any precipitation > 0 in next 6 hours?”
- alert only when:
  - current snapshot indicates rain in next 6h
  - previous snapshot did not

This avoids repeating the same warning on every run.

### Cooldown gating
Even if the decision says “alert,” sending is blocked if:
- the same alert type was sent in the last 2 hours (based on `alert_log`)

## Wind alert (next 6 hours)
### Decision logic (spike detection)
Simplified:
- compute max wind in next 6 hours for current and previous snapshots
- alert when:
  - current max wind ≥ 30 km/h
  - and increase vs previous is ≥ 15 km/h

### Cooldown gating
Same 2-hour cooldown logic via `alert_log`.

## How to evaluate alert usefulness (business framing)
Alert usefulness is not just accuracy — it’s decision value:

1. **Frequency**
   - Alerts per week should be low enough that users keep them enabled.

2. **Precision vs noise**
   - Too sensitive → alert fatigue
   - Too strict → missed events

3. **Lead time**
   - Alerts should arrive early enough to change actions (bring jacket, avoid cycling, etc.)

4. **Stability**
   - Avoid flip-flopping alerts every hour through change-aware logic and cooldowns

## Planned improvements
- Track evaluation metrics over time (alerts/week, lead time distribution)
- Compare alerts against observed outcomes (optional; would require observed weather ingestion)
- Add “temperature delta” alerts / brief enrichment for sudden drops or spikes
