-- Case 03 — Proposed end-to-end NAV Break Control Pipeline (2025)

-- Use case:
--   Build a maintainable, audit-ready NAV break control pipeline for 2025 using FA and Custody data.
--   Replace fragile macros with a transparent, step-based SQL workflow that any analyst can debug.

-- Sources:
--   • lux_funds  (Fund Accounting – “FA”)
--   • custody_nav (Custodian – “Custody”)

-- Materiality thresholds (absolute differences):
--   • Very_High  ≥ 300,000
--   • High       ≥ 200,000
--   • Moderate   ≥ 50,000
--   • Filter floor for exceptions: > 30,000

-- Core principle:
--   A NAV “difference” can only be evaluated when both books post a comparable value.
--   Join logic defines comparability. Missing-side cases must be explicitly exposed, not hidden.

-- Pipeline steps (business view):
--   Step 1: FA universe for 2025 — clean, validated FA rows.
--   Step 2: Custody universe for 2025 — same scope, matching filters.
--   Step 3: Normalised FA/Custody join — align naming conventions, unify keys.
--   Step 4: NAV differences + materiality — compute absolute gaps and classify size.
--   Step 5: Exception classification — identify Missing_FA, Missing_Custody, True_Break.

-- Step 1: FA base universe (2025)
WITH fa_base AS (
    SELECT
        fund_name,
        subfund_name,
        nav_date,
        account_number,
        amount       AS fa_amount,
        auditor,
        importance
    FROM lux_funds
    WHERE
        nav_date BETWEEN '2025-01-01' AND '2025-12-31'
        AND amount IS NOT NULL
        AND subfund_name IS NOT NULL
        AND importance <> 'Low'
),

-- Step 2: Custody base universe (2025)
custody_base AS (
    SELECT
        fund_name,
        subfund_name,
        nav_date,
        account_number,
        amount AS custody_amount
    FROM custody_nav
    WHERE
        nav_date BETWEEN '2025-01-01' AND '2025-12-31'
        AND amount IS NOT NULL
        AND subfund_name IS NOT NULL
),

-- Step 3: Normalized FA–Custody join
normalized_join AS (
    SELECT
        COALESCE(f.fund_name, c.fund_name)                     AS fund_name,
        COALESCE(f.subfund_name, c.subfund_name)               AS subfund_name,
        COALESCE(f.nav_date, c.nav_date)                       AS nav_date,
        COALESCE(f.account_number, c.account_number)           AS account_number,
        UPPER(TRIM(REPLACE(COALESCE(f.fund_name, c.fund_name), '_', ' ')))
            AS normalized_fund_name,
        UPPER(TRIM(REPLACE(COALESCE(f.subfund_name, c.subfund_name), '2', '')))
            AS normalized_subfund_name,
        f.fa_amount,
        c.custody_amount,
        f.auditor,
        f.importance
    FROM fa_base f
    FULL OUTER JOIN custody_base c
          ON UPPER(TRIM(REPLACE(f.fund_name, '_', ' ')))
             = UPPER(TRIM(REPLACE(c.fund_name, '_', ' ')))
         AND UPPER(TRIM(REPLACE(f.subfund_name, '2', '')))
             = UPPER(TRIM(REPLACE(c.subfund_name, '2', '')))
         AND f.nav_date = c.nav_date
         AND f.account_number = c.account_number
),

-- Step 4: Differences + materiality buckets
breaks_raw AS (
    SELECT
        fund_name,
        subfund_name,
        nav_date,
        account_number,
        normalized_fund_name,
        normalized_subfund_name,
        fa_amount,
        custody_amount,
        auditor,
        importance,
        COALESCE(fa_amount, 0) - COALESCE(custody_amount, 0)      AS diff_amount,
        ABS(COALESCE(fa_amount, 0) - COALESCE(custody_amount, 0)) AS diff_abs,
        CASE
            WHEN ABS(COALESCE(fa_amount, 0) - COALESCE(custody_amount, 0)) >= 300000 THEN 'Very_High'
            WHEN ABS(COALESCE(fa_amount, 0) - COALESCE(custody_amount, 0)) >= 200000 THEN 'High'
            WHEN ABS(COALESCE(fa_amount, 0) - COALESCE(custody_amount, 0)) >= 50000  THEN 'Moderate'
            ELSE 'Below_Threshold'
        END AS materiality_bucket
    FROM normalized_join
),

-- Step 5: Break classification
breaks_classified AS (
    SELECT
        fund_name,
        subfund_name,
        nav_date,
        account_number,
        normalized_fund_name,
        normalized_subfund_name,
        fa_amount,
        custody_amount,
        auditor,
        importance,
        diff_amount,
        diff_abs,
        materiality_bucket,
        CASE
            WHEN fa_amount IS NULL AND custody_amount IS NOT NULL THEN 'Missing_FA'
            WHEN custody_amount IS NULL AND fa_amount IS NOT NULL THEN 'Missing_Custody'
            WHEN diff_abs < 50000 THEN 'Below_Materiality'
            ELSE 'True_Break'
        END AS break_type
    FROM breaks_raw
)

-- Final output: detailed exceptions (operational and oversight use)
SELECT
    fund_name,
    subfund_name,
    nav_date,
    account_number,
    normalized_fund_name,
    normalized_subfund_name,
    fa_amount,
    custody_amount,
    auditor,
    importance,
    diff_amount,
    diff_abs,
    materiality_bucket,
    break_type
FROM breaks_classified
ORDER BY
    break_type,
    materiality_bucket DESC,
    diff_abs DESC,
    fund_name,
    subfund_name,
    nav_date;

-- Technical step explanation (technical view):
--   Step 1: Select FA rows for 2025 with valid amounts and clean identifiers.
--   Step 2: Select Custody rows for 2025 under the same data-quality rules.
--   Step 3: Normalise naming conventions and create a unified join on comparable keys.
--   Step 4: Compute FA–Custody differences and assign materiality buckets.
--   Step 5: Classify all rows into exception categories for NAV oversight workflows.
