-- Task: Bank & auditor growth summary for 2025
SELECT 
    fund_name,
    auditor,
    COUNT(*) AS rows_count,
    COUNT(DISTINCT subfund_name) AS distinct_subfunds,
    AVG(amount) AS avg_amount,
    AVG(estimated_amount) AS avg_estimated,
    AVG(estimated_amount) - AVG(amount) AS avg_diff
FROM lux_funds
WHERE
    nav_date BETWEEN '2025-01-01' AND '2025-12-31'
    AND importance IN ('High', 'Medium')
    AND beginning_service_date BETWEEN '2008-01-01' AND '2018-12-31'
    AND amount > previous_amount
GROUP BY fund_name, auditor
HAVING 
    COUNT(*) >= 3
    AND AVG(estimated_amount) > AVG(amount)
ORDER BY avg_diff DESC, rows_count DESC
LIMIT 5;
