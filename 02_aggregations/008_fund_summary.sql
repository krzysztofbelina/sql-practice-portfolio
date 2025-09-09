-- Task: Fund summary with counts, averages and max
SELECT
    fund_name,
    COUNT(*) AS fund_count,
    AVG(estimated_amount) AS avg_estimated,
    MAX(amount) AS max_amount
FROM lux_funds
WHERE
    beginning_service_date BETWEEN '2005-01-01' AND '2015-12-31'
    AND auditor IN ('EY', 'PwC')
GROUP BY fund_name
HAVING AVG(estimated_amount) > 50000000
ORDER BY max_amount DESC
LIMIT 5;
