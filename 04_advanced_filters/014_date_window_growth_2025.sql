-- Task: Historical start (<2012) with 2025 NAV and non-decreasing estimate
SELECT
    id,
    fund_name,
    subfund_name,
    auditor,
    beginning_service_date,
    nav_date,
    amount,
    previous_amount,
    estimated_amount
FROM lux_funds
WHERE
    beginning_service_date < '2012-01-01'
    AND nav_date BETWEEN '2025-01-01' AND '2025-12-31'
    AND auditor IN ('EY', 'Deloitte')
    AND importance != 'Low'
    AND amount BETWEEN 25000000 AND 95000000
    AND estimated_amount >= previous_amount
ORDER BY nav_date ASC, estimated_amount DESC
LIMIT 20;
