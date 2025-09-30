-- Objective: Identify high-importance funds audited by EY in the second half of 2025,
--            and compare fund accounting vs custody NAV amounts.

SELECT
    a.fund_name,
    a.subfund_name,
    a.nav_date,
    a.auditor,
    a.amount AS fa_amount,
    b.amount AS custody_amount,
    a.amount - b.amount AS difference
FROM lux_funds AS a
LEFT JOIN custody_nav AS b
    ON a.fund_name = b.fund_name
   AND a.nav_date = b.nav_date
   AND a.account_number = b.account_number
WHERE
    a.auditor = 'EY'
    AND a.importance = 'High'
    AND a.nav_date BETWEEN '2025-07-01' AND '2025-12-31'
ORDER BY 
    a.nav_date ASC,
    difference DESC
LIMIT 15;
