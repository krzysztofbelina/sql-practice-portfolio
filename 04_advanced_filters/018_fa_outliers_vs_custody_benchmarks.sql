-- Advanced Filter: FA NAV outlier screening vs global & fund-level Custody benchmarks
-- Purpose:
--   Flag FA NAV rows where the amount is simultaneously above:
--     1) Global Custody average (non-correlated subquery), and
--     2) Fund-level Custody average (correlated subquery by fund_name).
--   This highlights extreme FA values that stand out both globally and within
--   their specific fund when compared to Custody.

-- Logic:
--   - Non-correlated subquery: AVG(amount) over all Custody rows.
--   - Correlated subquery: AVG(amount) over Custody rows for the same fund_name.
--   - Keep FA rows where amount > both averages and amount IS NOT NULL.


SELECT
    f.fund_name,
    f.subfund_name,
    f.nav_date,
    f.amount AS fa_amount
FROM lux_funds AS f
WHERE
    f.amount IS NOT NULL
    AND f.amount > (
        SELECT
            AVG(c.amount)
        FROM custody_nav AS c
        WHERE c.amount IS NOT NULL
    )
    AND f.amount > (
        SELECT
            AVG(c2.amount)
        FROM custody_nav AS c2
        WHERE
            c2.fund_name = f.fund_name
            AND c2.amount IS NOT NULL
    )
ORDER BY
    fa_amount DESC,
    f.fund_name,
    f.subfund_name,
    f.nav_date;
