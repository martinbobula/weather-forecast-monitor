# Tradeoffs and Roadmap

This repository is intentionally designed as a **local-first, SQL-first portfolio project**. The goal is to demonstrate structured data pipeline thinking, decision logic, and explainability — not production scale or infrastructure complexity.

Several limitations are intentional and reflect tradeoffs made to keep the system simple, inspectable, and focused on decision-support signals.

---

## Key tradeoffs (current state)

### 1. Local scheduling (macOS `launchd`)

**Pros:**
- Simple and reliable for a personal project  
- No external infrastructure required  
- Easy debugging and log inspection  

**Cons:**
- Not portable across environments  
- Depends on a specific user path and machine state  
- Not always-on if the laptop is off  

---

### 2. Single-location (Prague only)

**Pros:**
- Clear scope and faster iteration  
- Focus on signal logic rather than scaling concerns  
- Simplifies schema and modeling  

**Cons:**
- Multi-location support would require parameterization  
- Alert logic is not yet generalized across geographies  

---

### 3. Rule-based thresholds (hard-coded values)

Examples:
- wind ≥ 30 km/h  
- wind increase ≥ 15 km/h  
- precipitation > 0  

**Pros:**
- Easy to reason about  
- Fully transparent decision logic  
- Simple SQL implementation  

**Cons:**
- Thresholds are not yet data-informed  
- “Significant change” is based on intuition, not historical distributions  
- No adaptive or seasonal context  

---

### 4. SQL models rebuild tables (`DROP/CREATE`)

**Pros:**
- Deterministic and easy to debug  
- Clear PoC-style modeling  
- No migration complexity  

**Cons:**
- No schema versioning  
- Not optimized for incremental production workflows  

---

### 5. Limited packaging and mixed import styles

**Pros:**
- Fast iteration during development  
- Minimal upfront structure  

**Cons:**
- Not structured as a formal Python package  
- `sys.path` adjustments reduce portability  
- Dependencies are not yet fully formalized  

---

### 6. No automated tests

**Pros:**
- Faster initial delivery  
- Validation performed through EDA queries and monitoring tables  

**Cons:**
- No automated verification of alert logic  
- Behavior correctness depends on manual inspection  

---

# Roadmap (Next Iterations)

The next evolution of this project focuses on **signal quality, explainability, and AI-assisted analysis**, rather than scaling or infrastructure complexity.

---

## 1. AI Explainability Assistant (Primary Focus)

Introduce an LLM-based assistant that sits on top of the structured pipeline and helps interpret system behavior.

Example capabilities:
- Explain why a rain or wind alert triggered  
- Analyze why alert frequency increased on a given day  
- Compare forecast snapshots and summarize meaningful changes  
- Suggest whether current thresholds appear too sensitive  

The AI layer would analyze:
- `snapshots_hourly`
- monitoring tables
- alert decision tables
- alert logs
- morning brief outputs  

The goal is not weather prediction, but **system interpretation and explainability**.

---

## 2. Forecast Change Detection

Detect and surface meaningful changes between:
- consecutive forecast snapshots  
- current forecast vs previous day  
- recent historical patterns  

Example output:

> “Temperature expected to drop by 6°C compared to yesterday afternoon.”

This would improve practical decision awareness (clothing, commuting, outdoor planning).

---

## 3. Alert Evaluation Metrics

Introduce structured evaluation metrics to assess alert usefulness.

Examples:
- alerts per day / week  
- lead time before event  
- forecast volatility  
- false positives vs missed events  

This allows thresholds to be tuned based on observed behavior rather than intuition.

---

## 4. Data-Informed Threshold Tuning

Move from purely rule-based thresholds toward data-informed detection.

Possible approaches:
- percentile-based alerts (e.g., wind > 90th percentile of recent values)  
- anomaly detection using z-scores  
- season-aware weighting of weather variables  

This would shift the system from fixed rules to statistically grounded signals.

---

## 5. Configuration & Packaging Improvements

Improve maintainability by:
- centralizing configuration (location, thresholds, time windows)  
- converting the repository into a proper Python package  
- removing `sys.path` adjustments  
- formalizing dependencies (`requirements.txt` or `pyproject.toml`)  

---

## 6. Automated Logic Testing

Introduce tests to validate decision logic and formatting.

Examples:
- unit tests for alert models  
- synthetic forecast datasets for integration testing  
- validation tests for morning brief formatting  

---

## 7. Optional Production Deployment

Migrate from local scheduling to a lightweight production setup:

- cloud scheduler (GitHub Actions, cron job, or small VM)  
- proper secrets management  
- centralized logging  

This would improve reliability while keeping the system intentionally simple.

---

## Strategic Direction

The long-term direction of the project is:

1. Maintain a transparent, SQL-first rule-based core  
2. Layer AI on top for interpretation and analysis  
3. Gradually introduce data-informed tuning and evaluation  

This ensures the system remains:
- explainable  
- inspectable  
- decision-oriented  
- portfolio-relevant  
