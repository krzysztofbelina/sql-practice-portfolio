-- Task: Select top 3 funds by amount (descending)
SELECT
    id,
    fund_name,
    amount
FROM lux_funds
ORDER BY amount DESC
LIMIT 3;
