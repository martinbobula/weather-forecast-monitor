# Executive Summary

## Context and goal
This project is a local weather “decision-support” pipeline for Prague. The goal is not to “get weather data” — it is to reduce **last-minute surprises** by converting a forecast API into **actionable signals** (alerts) and a daily **morning brief**.

Primary users:
- Me / my girlfriend / friends in Prague

Primary decisions supported:
- What to wear / whether to bring rain gear
- Whether wind/rain risk is high enough to change plans
- Quick daily understanding of the next 12 hours (dayparts)

## What the system does
- Fetches hourly forecasts from Open-Meteo
- Stores raw JSON snapshots on disk (raw archive)
- Loads snapshots into DuckDB and normalizes into a row-based hourly table
- Runs monitoring checks (freshness, missing hours, change rate)
- Computes change-aware alerts (rain/wind next 6 hours) with cooldown gating
- Builds a daily morning brief (12-hour horizon + dayparts)
- Prints and/or sends notifications to Telegram
- Runs via macOS `launchd` (or manually)

## Why it is built this way (portfolio intent)
This repo is a template for turning an external API into decision-support outputs using:
- Clear data layers (raw → modeled → outputs)
- SQL-first modeling for transparency and auditability
- Reliability patterns (idempotency, monitoring tables, cooldowns, logs)
- Practical constraints (local-first, no overengineering)

## Success criteria
- Alerts are infrequent enough to remain trusted, but timely enough to prevent surprises
- Alerts reflect meaningful forecast changes (not repeated noise)
- Morning brief is concise and readable in <30 seconds
- Runs are traceable and debuggable via logs + monitoring tables
- Transformations and business rules are auditable in SQL

## Non-goals (intentional scope)
- No UI or mobile app
- No ML forecasting (Open-Meteo is the forecast provider)
- No multi-city scaling in the current version
- No cloud deployment in this repo (a production path is documented as future work)
