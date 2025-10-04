-- Case Study: Reconciling reported NAV vs. reference values with NULL handling

SELECT
    fund_name,
    subfund_name,
    nav_date,
    account_number,
    previous_amount,
    amount,
    estimated_amount,
    COALESCE(amount, estimated_amount) AS reported_current_value,
    GREATEST(COALESCE(previous_amount, 0), COALESCE(estimated_amount, 0)) AS reference_value,
    ABS(
        COALESCE(amount, estimated_amount) -
        GREATEST(COALESCE(previous_amount, 0), COALESCE(estimated_amount, 0))
    ) AS absolute_difference
FROM custody_nav
WHERE
    nav_date BETWEEN '2025-01-01' AND '2025-12-31'
    AND COALESCE(amount, estimated_amount) <>
        GREATEST(COALESCE(previous_amount, 0), COALESCE(estimated_amount, 0))
ORDER BY
    absolute_difference DESC,
    nav_date ASC
LIMIT 25;
