-- Task: Select funds where subfund_name starts with 'M'
SELECT
    id,
    fund_name,
    subfund_name,
    nav_date,
    amount
FROM lux_funds
WHERE subfund_name LIKE 'M%'
ORDER BY nav_date ASC, amount DESC;
