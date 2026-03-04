# Tradeoffs and Roadmap

This repo is designed as a local-first, SQL-first portfolio project. Some limitations are intentional.

## Key tradeoffs (current state)
### 1. Local scheduling (macOS `launchd`)
Pros:
- simple and reliable on a personal laptop
Cons:
- not portable across environments
- depends on a specific user path and machine state

### 2. Single-location (Prague)
Pros:
- clear scope and faster iteration
Cons:
- multi-city requires parameterization and schema changes

### 3. Hard-coded thresholds and time windows
Pros:
- easy to reason about
Cons:
- tuning and reuse would be easier with centralized config

### 4. SQL models rebuild tables (DROP/CREATE)
Pros:
- simple, deterministic for a PoC
Cons:
- no migrations/versioning

### 5. Limited packaging + mixed import styles
Pros:
- quick iteration
Cons:
- less “production Python” hygiene

### 6. No automated tests
Pros:
- faster initial delivery
Cons:
- correctness is validated manually via EDA and monitoring

## Roadmap (pragmatic next steps)
1. **Temperature delta detection in morning brief**
   - highlight significant drops/spikes vs previous day or previous forecast
2. **Centralized configuration**
   - move thresholds, locations, and time windows to YAML/JSON
3. **Packaging and dependencies**
   - add `requirements.txt` or `pyproject.toml`, remove `sys.path` hacks
4. **Cloud scheduling**
   - migrate from launchd to GitHub Actions / VM cron / scheduler
5. **Testing**
   - unit tests for alert and brief logic
   - small integration test with sample JSON
6. **Extend observability**
   - log pipeline step status into `etl_runs`
   - optional “health summary” message
