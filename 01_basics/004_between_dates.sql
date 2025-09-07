-- Task: Select funds with beginning_service_date between 2005 and 2015
SELECT
    id,
    fund_name,
    beginning_service_date
FROM lux_funds
WHERE beginning_service_date BETWEEN '2005-01-01' AND '2015-12-31'
ORDER BY beginning_service_date ASC;
