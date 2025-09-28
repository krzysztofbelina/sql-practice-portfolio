-- Seed custody_nav from lux_funds with controlled mismatches for training joins/reconciliation.
-- A: matched rows with small numeric drifts
INSERT INTO custody_nav (
    id, fund_name, subfund_name, account_number, nav_date,
    amount, previous_amount, estimated_amount, source
)
SELECT
    id, fund_name, subfund_name, account_number, nav_date,
    amount + ((id % 5 - 2) * 10000)::NUMERIC(10,2),
    previous_amount + ((id % 7 - 3) * 5000)::NUMERIC(10,2),
    estimated_amount + ((id % 3 - 1) * 8000)::NUMERIC(10,2),
    'Custody'
FROM lux_funds
WHERE id % 3 <> 0;

-- B: date shifted by +1 day (no match on nav_date)
INSERT INTO custody_nav (
    id, fund_name, subfund_name, account_number, nav_date,
    amount, previous_amount, estimated_amount, source
)
SELECT
    id + 100000, fund_name, subfund_name, account_number, (nav_date + INTERVAL '1 day')::DATE,
    amount + ((id % 4 - 2) * 7500)::NUMERIC(10,2),
    previous_amount,
    estimated_amount,
    'Custody'
FROM lux_funds
WHERE id % 10 = 0;

-- C: account number altered (no match on account_number)
INSERT INTO custody_nav (
    id, fund_name, subfund_name, account_number, nav_date,
    amount, previous_amount, estimated_amount, source
)
SELECT
    id + 200000, fund_name, subfund_name,
    CAST(SUBSTRING(account_number FOR 33) || '9' AS CHAR(34)),
    nav_date,
    amount,
    previous_amount,
    estimated_amount,
    'Custody'
FROM lux_funds
WHERE id % 15 = 0;

-- D: custody-only rows (exist only in custody source)
INSERT INTO custody_nav (
    id, fund_name, subfund_name, account_number, nav_date,
    amount, previous_amount, estimated_amount, source
)
SELECT
    id + 300000, fund_name, subfund_name || '_EXT', account_number, nav_date,
    (amount * 0.98)::NUMERIC(10,2),
    (previous_amount * 0.98)::NUMERIC(10,2),
    (estimated_amount * 0.98)::NUMERIC(10,2),
    'Custody'
FROM lux_funds
WHERE id % 20 = 0;
