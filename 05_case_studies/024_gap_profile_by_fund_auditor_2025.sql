-- Case Study: Fund and auditor gap profile analysis for 2025
-- Objective: Identify funds and auditors with the largest valuation discrepancies
-- using COALESCE and GREATEST to normalize NULLs and capture the biggest differences.

SELECT
    fund_name,
    auditor,
    COUNT(*) AS total_records,
    AVG(
        GREATEST(
            ABS(COALESCE(amount, 0) - COALESCE(estimated_amount, 0)),
            ABS(COALESCE(previous_amount, 0) - COALESCE(estimated_amount, 0))
        )
    ) AS average_larger_gap,
    MAX(
        GREATEST(
            ABS(COALESCE(amount, 0) - COALESCE(estimated_amount, 0)),
            ABS(COALESCE(previous_amount, 0) - COALESCE(estimated_amount, 0))
        )
    ) AS max_larger_gap
FROM lux_funds
WHERE
    nav_date BETWEEN '2025-01-01' AND '2025-12-31'
GROUP BY
    fund_name,
    auditor
HAVING
    COUNT(*) >= 2
    AND AVG(
        GREATEST(
            ABS(COALESCE(amount, 0) - COALESCE(estimated_amount, 0)),
            ABS(COALESCE(previous_amount, 0) - COALESCE(estimated_amount, 0))
        )
    ) > 10000
ORDER BY
    average_larger_gap DESC,
    total_records DESC
LIMIT 10;
