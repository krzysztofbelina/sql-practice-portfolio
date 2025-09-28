-- Case Study 5: Reconciliation mismatches between fund accounting and custody (2025)
-- Objective: list unmatched rows and amount discrepancies between sources.

SELECT
    a.fund_name,
    a.nav_date,
    a.account_number,
    a.auditor,
    a.amount AS fa_amount,
    b.amount AS custody_amount
FROM lux_funds AS a
LEFT JOIN custody_nav AS b
    ON a.fund_name = b.fund_name
   AND a.nav_date = b.nav_date
   AND a.account_number = b.account_number
WHERE
    a.nav_date BETWEEN '2025-01-01' AND '2025-12-31'
    AND a.importance IN ('High', 'Medium')
    AND a.auditor IN ('EY', 'PwC')
    AND (
        b.account_number IS NULL
        OR a.amount <> b.amount
    )
ORDER BY 
    a.fund_name ASC,
    a.nav_date ASC
LIMIT 25;
