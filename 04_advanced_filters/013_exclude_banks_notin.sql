-- Advanced filter: exclude Deutsche_Bank and HSBC, auditor not PwC, 2025 High importance, amount > 50M
SELECT
    id,
    fund_name,
    auditor,
    nav_date,
    amount,
    importance
FROM lux_funds
WHERE 
    fund_name NOT IN ('Deutsche_Bank', 'HSBC')
    AND auditor != 'PwC'
    AND nav_date BETWEEN '2025-01-01' AND '2025-12-31'
    AND importance = 'High'
    AND amount > 50000000
ORDER BY amount DESC
LIMIT 15;
