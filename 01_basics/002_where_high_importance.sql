-- Task: Select id, fund_name, auditor, amount where importance = 'High'
SELECT
    id,
    fund_name,
    auditor,
    amount
FROM lux_funds
WHERE importance = 'High';
