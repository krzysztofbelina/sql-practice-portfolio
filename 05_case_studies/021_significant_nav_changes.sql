-- Case Study: Detect significant NAV changes
-- Identify funds where the NAV difference vs previous period exceeds 1,000,000 (up or down).
-- Focus only on EY and KPMG auditors with High/Medium importance.
-- Return both the absolute difference and normalized growth ratio.

SELECT
    fund_name,
    subfund_name,
    auditor,
    nav_date,
    amount,
    previous_amount,
    ABS(amount - previous_amount) AS abs_diff,
    ROUND(amount / previous_amount, 2) AS growth_ratio
FROM lux_funds
WHERE
    ABS(amount - previous_amount) > 1000000
    AND auditor IN ('EY', 'KPMG')
    AND importance IN ('High', 'Medium')
ORDER BY abs_diff DESC;
