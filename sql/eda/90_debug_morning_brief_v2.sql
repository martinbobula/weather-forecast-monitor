SELECT *
FROM (
  -- keep it simple: just run the model SQL
  -- (DuckDB doesn't have model refs, so we copy/paste via include pattern later if you want)
  -- For now: paste the model content here OR just run the model file directly.
  SELECT 1
) t;