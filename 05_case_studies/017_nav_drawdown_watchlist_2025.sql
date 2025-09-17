-- Case Study 1: NAV drawdown watchlist for 2025 (non-empty constraints)
SELECT
    fund_name,
    COUNT(*) AS drop_count,
    AVG(GREATEST(previous_amount - amount, previous_amount - estimated_amount)) AS avg_drop,
    MAX(GREATEST(previous_amount - amount, previous_amount - estimated_amount)) AS max_drop
FROM lux_funds
WHERE
    nav_date BETWEEN '2025-01-01' AND '2025-12-31'
    AND importance IN ('High', 'Medium')
    AND auditor IN ('EY', 'KPMG', 'Deloitte')
    AND (amount < previous_amount OR estimated_amount < previous_amount)
GROUP BY fund_name
HAVING COUNT(*) >= 1
ORDER BY max_drop DESC, drop_count DESC
LIMIT 10;
