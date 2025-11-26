-- Advanced Filter: Subfund-level FA outlier detection (correlated subquery)
-- Purpose:
--   Identify FA NAV rows where the amount is significantly above the historical
--   average for the same subfund, treating them as potential outliers.

-- Logic:
--   - For each row in lux_funds (f1), compute the average amount for the same
--     subfund (f2) and keep rows where amount > 1.5 * local average.
--   - Exclude NULL amounts from both the row and the average.

SELECT
    f1.fund_name,
    f1.subfund_name,
    f1.nav_date,
    f1.amount AS fa_amount
FROM lux_funds AS f1
WHERE
    f1.amount IS NOT NULL
    AND f1.amount > 1.5 * (
        SELECT
            AVG(f2.amount)
        FROM lux_funds AS f2
        WHERE
            f2.subfund_name = f1.subfund_name
            AND f2.amount IS NOT NULL
    )
ORDER BY
    fa_amount DESC,
    f1.fund_name,
    f1.subfund_name,
    f1.nav_date;
