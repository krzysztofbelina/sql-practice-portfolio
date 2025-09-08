-- Task: Auditor summary for 2025 (counts and averages)
SELECT
    auditor,
    COUNT(*) AS total_funds,
    COUNT(DISTINCT fund_name) AS distinct_banks,
    AVG(amount) AS avg_amount
FROM lux_funds
WHERE
    nav_date BETWEEN '2025-01-01' AND '2025-12-31'
    AND importance != 'Low'
GROUP BY auditor
HAVING COUNT(*) >= 2
ORDER BY avg_amount DESC, total_funds DESC
LIMIT 3;
