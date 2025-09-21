-- Case Study: Fund–Auditor growth analysis 2025
-- For each (fund_name, auditor) pair in 2025 with importance High or Medium:
-- - Count records
-- - Calculate average growth vs previous_amount
-- - Calculate average estimated growth vs previous_amount
-- - Find maximum growth vs previous_amount
-- Keep only groups with at least 3 records and positive average growth in one of the measures.
-- Return top 10 sorted by max_growth (desc) and rows_count (desc).
SELECT
    auditor,
    fund_name,
    COUNT(*) AS rows_count,
    AVG(amount - previous_amount) AS avg_growth,
    AVG(estimated_amount - previous_amount) AS avg_est_growth,
    MAX(amount - previous_amount) AS max_growth
FROM lux_funds
WHERE
    nav_date BETWEEN '2025-01-01' AND '2025-12-31'
    AND importance IN ('High', 'Medium')
GROUP BY
    auditor,
    fund_name
HAVING
    COUNT(*) >= 3
    AND (AVG(amount - previous_amount) > 0 OR AVG(estimated_amount - previous_amount) > 0)
ORDER BY 
    max_growth DESC,
    rows_count DESC
LIMIT 10;
