-- Task: Select funds audited by EY or KPMG
SELECT
    id,
    fund_name,
    auditor
FROM lux_funds
WHERE auditor IN ('EY', 'KPMG')
ORDER BY auditor ASC, fund_name ASC;
