-- Task: Negative growth in 2025 (current or estimated below previous) – PostgreSQL GREATEST
SELECT 
    id,
    fund_name,
    subfund_name,
    auditor,
    nav_date,
    amount,
    previous_amount,
    estimated_amount,
    GREATEST(previous_amount - amount, previous_amount - estimated_amount) AS drop_value
FROM lux_funds
WHERE
    nav_date BETWEEN '2025-01-01' AND '2025-12-31'
    AND importance IN ('High', 'Medium')
    AND auditor IN ('EY', 'KPMG', 'Deloitte')
    AND (amount < previous_amount OR estimated_amount < previous_amount)
    AND amount BETWEEN 25000000 AND 95000000
ORDER BY drop_value DESC, previous_amount DESC
LIMIT 20;
