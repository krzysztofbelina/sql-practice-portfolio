-- Case Study: H2 2025 NAV breaks above per-fund 2025 FA average (FA vs Custody)
-- Purpose:
--   Identify H2 2025 NAV rows where FA amount exceeds the fund’s full-year 2025
--   FA benchmark and where the FA–Custody difference is materially relevant.
-- Method:
--   Step 1: Compute per-fund FA average across full 2025 (benchmark).
--   Step 2: Join FA and Custody, attach benchmark, apply H2 filters and threshold.

-- Step 1: Per-fund FA average for 2025
WITH fa_avg_per_fund_2025 AS (
    SELECT
        fund_name,
        AVG(amount) AS avg_fa_2025
    FROM lux_funds
    WHERE
        nav_date BETWEEN '2025-01-01' AND '2025-12-31'
        AND amount IS NOT NULL
    GROUP BY
        fund_name
)

-- Step 2: H2 2025 NAV breaks above per-fund average
SELECT
    f.fund_name,
    f.subfund_name,
    f.nav_date,
    f.account_number,
    f.auditor,
    f.amount  AS fa_amount,
    c.amount  AS custody_amount,
    ABS(f.amount - c.amount) AS abs_diff,
    fa.avg_fa_2025
FROM lux_funds AS f
JOIN custody_nav AS c
      ON f.fund_name      = c.fund_name
     AND f.account_number = c.account_number
     AND f.nav_date       = c.nav_date
JOIN fa_avg_per_fund_2025 AS fa
      ON f.fund_name = fa.fund_name
WHERE
    f.nav_date BETWEEN '2025-07-01' AND '2025-12-31'   -- H2 2025
    AND f.importance <> 'Low'
    AND f.auditor IN ('EY', 'KPMG', 'Deloitte')
    AND f.amount IS NOT NULL
    AND c.amount IS NOT NULL
    AND f.amount > fa.avg_fa_2025                     -- above benchmark
    AND ABS(f.amount - c.amount) > 5000               -- material threshold
ORDER BY
    f.fund_name,
    abs_diff DESC;
