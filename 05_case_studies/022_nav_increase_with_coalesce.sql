-- Case Study: Detecting NAV increases with NULL handling

SELECT
    fund_name,
    subfund_name,
    auditor,
    nav_date,
    previous_amount,
    COALESCE(amount, estimated_amount) AS effective_current_value,
    COALESCE(amount, estimated_amount) - previous_amount AS increase
FROM lux_funds
WHERE
    auditor IN ('EY', 'KPMG', 'Deloitte', 'PwC')
    AND nav_date BETWEEN '2025-01-01' AND '2025-12-31'
    AND COALESCE(amount, estimated_amount) > previous_amount
ORDER BY
    increase DESC,
    nav_date ASC
LIMIT 20;
