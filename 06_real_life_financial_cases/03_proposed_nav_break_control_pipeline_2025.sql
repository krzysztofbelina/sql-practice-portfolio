-- Proposed end-to-end NAV Break Control Pipeline for 2025 (FA vs Custody)
-- Business context:
--   In large fund-administration environments (Lux FA / Custody), NAV controls often rely
--   on legacy Excel/VBA macros owned by a single technical specialist. These tools are
--   fragile, tied to strict file structures, and frequently become a single point of failure:
--   when the macro owner is unavailable, even minor issues (like a changed file extension)
--   can halt production because process analysts and new joiners cannot debug the logic.
--
--   This proposed end-to-end, exception-based NAV control pipeline replaces such fragile
--   workflows with a transparent, step-by-step SQL process. Each layer represents a clear
--   business task: selecting FA/Custody universes, normalising naming differences, joining
--   both books, applying materiality thresholds, and classifying exceptions. The structure
--   is maintainable, audit-friendly and hand-over ready — designed so both technical and
--   non-technical staff can follow and debug it without relying on a single expert.
--
-- Purpose:
--   Provide a 2025 FA–Custody NAV break pipeline that:
--     • builds clean FA and Custody universes for 2025,
--     • aligns naming conventions between books,
--     • computes NAV differences with materiality-based prioritisation,
--     • classifies exceptions for oversight, escalation, and daily control.
--
-- Method:
--   Step 1: FA base universe (clean 2025 scope).
--   Step 2: Custody base universe (matching scope).
--   Step 3: Normalised FA–Custody join (consistent keys).
--   Step 4: NAV differences + materiality buckets.
--   Step 5: Exception classification.

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

-- Final output: detailed exceptions for operational or oversight review
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

-- Technical step explanations:
--   Step 1 (fa_base): Selects FA entries for 2025 with clean naming and valid amounts.
--   Step 2 (custody_base): Mirrors Step 1 on Custody data to ensure aligned universes.
--   Step 3 (normalized_join): Normalises naming conventions and joins FA/Custody on consistent keys.
--   Step 4 (breaks_raw): Computes NAV differences and applies multi-level materiality thresholds.
--   Step 5 (breaks_classified): Converts raw differences into exception categories for oversight workflows.
