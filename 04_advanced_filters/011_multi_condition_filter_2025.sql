-- Task: Multi-condition filter for 2025
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
    auditor IN ('EY', 'KPMG', 'Deloitte')
    AND importance != 'Low'
    AND nav_date BETWEEN '2025-01-01' AND '2025-12-31'
    AND beginning_service_date BETWEEN '2005-01-01' AND '2018-12-31'
    AND amount BETWEEN 30000000 AND 95000000
    AND (subfund_name LIKE 'M%' OR subfund_name LIKE 'S%')
ORDER BY nav_date ASC, amount DESC
LIMIT 20;
