-- Task: Subfund diversity by bank (2025 scope)
-- Metrics: DISTINCT subfunds, MIN/MAX/AVG(amount)
SELECT
    fund_name,
    COUNT(DISTINCT subfund_name) AS subfund_count,
    MAX(amount) AS max_amount,
    MIN(amount) AS min_amount,
    AVG(amount) AS avg_amount
FROM lux_funds
WHERE
    nav_date BETWEEN '2025-01-01' AND '2025-12-31'
    AND importance IN ('High', 'Medium')
GROUP BY fund_name
HAVING 
    COUNT(DISTINCT subfund_name) >= 2
    AND MAX(amount) > 60000000
ORDER BY 
    subfund_count DESC,
    max_amount DESC
LIMIT 5;
