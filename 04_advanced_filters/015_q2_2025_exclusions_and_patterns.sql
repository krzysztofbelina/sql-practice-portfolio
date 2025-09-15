-- Advanced filter: Q2 2025, exclusions and name patterns
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
    fund_name != 'HSBC'
    AND auditor IN ('EY', 'Deloitte')
    AND nav_date BETWEEN '2025-04-01' AND '2025-06-30'
    AND importance IN ('High', 'Medium')
    AND (
        beginning_service_date < '2010-01-01'
        OR beginning_service_date > '2016-12-31'
    )
    AND amount NOT BETWEEN 40000000 AND 70000000
    AND (
        subfund_name LIKE 'H%'
        OR subfund_name LIKE '%on%'
    )
ORDER BY nav_date ASC, amount DESC
LIMIT 20;
