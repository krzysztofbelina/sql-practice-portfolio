-- Task: Filter BNP_Paribas / JP_Morgan with Medium importance in 2025 (EY/KPMG)
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
    fund_name IN ('BNP_Paribas', 'JP_Morgan')
    AND auditor IN ('EY', 'KPMG')
    AND nav_date BETWEEN '2025-01-01' AND '2025-09-30'
    AND importance = 'Medium'
    AND amount BETWEEN 30000000 AND 80000000
    AND estimated_amount > previous_amount
ORDER BY nav_date ASC, amount DESC
LIMIT 25;
