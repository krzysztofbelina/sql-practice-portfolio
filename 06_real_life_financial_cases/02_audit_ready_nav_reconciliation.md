# Case 02 — Why joins matter in NAV reconciliation (and when `COALESCE` fails)
Use case: identify true breaks vs timing/unposted items in daily NAV reconciliation, using two sources:
- `lux_funds` (fund accounting, “FA”)
- `custody_nav` (custodian, “Custody”)

**Materiality thresholds** (absolute amounts, stable across scenarios):
- `Very_High` ≥ 300,000
- `High` ≥ 200,000
- `Moderate` ≥ 50,000
- **Filter floor for exceptions**: `> 30,000`

**Core principle:** Keys define comparability. If one side has not posted a NAV for a given `(fund_name, subfund_name, nav_date)`, it is **not** a financial “difference” but a **missing match**. Only a join can detect that reliably. `COALESCE` alone cannot.

---

## 1) Naive variance with `COALESCE` on matched pairs only
Purpose: show clean, absolute-only variance on **matched** keys. Valid **only** when both sides posted a NAV for the day. It hides missing matches by definition.

```sql
SELECT
  f.fund_name,
  f.subfund_name,
  f.nav_date,
  f.amount  AS fa_amount,
  c.amount  AS custody_amount,
  ABS(COALESCE(f.amount, 0) - COALESCE(c.amount, 0)) AS absolute_difference_threshold_30000,
  CASE
    WHEN ABS(COALESCE(f.amount, 0) - COALESCE(c.amount, 0)) >= 300000 THEN 'Very_High'
    WHEN ABS(COALESCE(f.amount, 0) - COALESCE(c.amount, 0)) >= 200000 THEN 'High'
    WHEN ABS(COALESCE(f.amount, 0) - COALESCE(c.amount, 0)) >= 50000  THEN 'Moderate'
    ELSE 'Low'
  END AS variance_bucket,
  COUNT(*) OVER() AS exception_count
FROM lux_funds AS f
INNER JOIN custody_nav AS c
  ON f.fund_name    = c.fund_name
 AND f.subfund_name = c.subfund_name
 AND f.nav_date     = c.nav_date
WHERE
  f.amount IS NOT NULL
  AND c.amount IS NOT NULL
  AND ABS(COALESCE(f.amount, 0) - COALESCE(c.amount, 0)) > 30000
ORDER BY
  absolute_difference_threshold_30000 DESC,
  f.fund_name,
  f.subfund_name,
  f.nav_date;
```

**What it proves**
- Produces a crisp break list with buckets on matched pairs.
- **But** it cannot see “missing” records (unposted/timing), because unmatched rows are discarded by `INNER JOIN`.

---

## 2) LEFT ANTI JOIN — why it does **not** detect value differences
Purpose: show FA rows **missing on Custody**. Anti-join semantics are binary on the key: either a match exists or it does not. It never evaluates value differences for matched rows.

```sql
SELECT
  f.fund_name,
  f.subfund_name,
  f.nav_date,
  f.amount            AS fa_amount,
  f.estimated_amount  AS fa_estimated_amount,
  COUNT(*) OVER()     AS fa_only_count
FROM lux_funds AS f
LEFT JOIN custody_nav AS c
  ON f.fund_name    = c.fund_name
 AND f.subfund_name = c.subfund_name
 AND f.nav_date     = c.nav_date
WHERE
  c.fund_name IS NULL
ORDER BY
  f.fund_name, f.subfund_name, f.nav_date;
```

**Why this cannot see value breaks**
- If a Custody row **exists** for the key, `c.*` is **not** `NULL`, so the anti condition fails regardless of amounts.
- Adding `OR f.amount <> c.amount` corrupts the logic: the anti part (`c IS NULL`) and the value comparison (`<>`) refer to **different** subsets and do not combine into a single “break” concept.

---

## 3) FULL ANTI JOIN — symmetric missing items only, still no value differences
Purpose: union of “FA-only” and “Custody-only” items to expose **both** sides’ missing rows. Still binary on key presence; still no evaluation of value variance for matched pairs.

```sql
-- FA-only leg
SELECT
  f.fund_name,
  f.subfund_name,
  f.nav_date,
  f.amount            AS fa_amount,
  NULL::numeric       AS custody_amount,
  'FA_only'           AS unmatched_side,
  COUNT(*) OVER()     AS unmatched_total
FROM lux_funds AS f
LEFT JOIN custody_nav AS c
  ON f.fund_name    = c.fund_name
 AND f.subfund_name = c.subfund_name
 AND f.nav_date     = c.nav_date
WHERE c.fund_name IS NULL

UNION ALL

-- Custody-only leg
SELECT
  c.fund_name,
  c.subfund_name,
  c.nav_date,
  NULL::numeric      AS fa_amount,
  c.amount           AS custody_amount,
  'Custody_only'     AS unmatched_side,
  COUNT(*) OVER()    AS unmatched_total
FROM custody_nav AS c
LEFT JOIN lux_funds AS f
  ON f.fund_name    = c.fund_name
 AND f.subfund_name = c.subfund_name
 AND f.nav_date     = c.nav_date
WHERE f.fund_name IS NULL

ORDER BY
  unmatched_side, fund_name, subfund_name, nav_date;
```

**What it proves**
- Captures **missing** matches on both sides cleanly.
- Still **does not** list rows where both sides exist but values differ. Anti-joins cannot express “same key, different amount”.

---

## 4) FULL OUTER JOIN — the only complete detection (missing **and** value differences)
Purpose: one pass that yields:
1) FA-only rows,
2) Custody-only rows,
3) Matched-but-different rows above threshold.

```sql
SELECT
  q.*
FROM (
  SELECT
    -- keep raw keys from each side to preserve provenance
    f.fund_name    AS fa_fund_name,
    f.subfund_name AS fa_subfund_name,
    f.nav_date     AS fa_nav_date,
    c.fund_name    AS custody_fund_name,
    c.subfund_name AS custody_subfund_name,
    c.nav_date     AS custody_nav_date,

    -- values for inspection
    f.amount AS fa_amount,
    c.amount AS custody_amount,

    -- classify row type
    CASE
      WHEN f.fund_name IS NULL THEN 'Custody_only'
      WHEN c.fund_name IS NULL THEN 'FA_only'
      WHEN ABS(COALESCE(f.amount, 0) - COALESCE(c.amount, 0)) > 30000 THEN 'Matched_but_Different'
      ELSE 'Matched_and_Within_Threshold'
    END AS status,

    -- stable variance buckets for matched-different class only
    CASE
      WHEN f.fund_name IS NOT NULL
       AND c.fund_name IS NOT NULL
       AND ABS(COALESCE(f.amount, 0) - COALESCE(c.amount, 0)) >= 300000 THEN 'Very_High'
      WHEN f.fund_name IS NOT NULL
       AND c.fund_name IS NOT NULL
       AND ABS(COALESCE(f.amount, 0) - COALESCE(c.amount, 0)) >= 200000 THEN 'High'
      WHEN f.fund_name IS NOT NULL
       AND c.fund_name IS NOT NULL
       AND ABS(COALESCE(f.amount, 0) - COALESCE(c.amount, 0)) >= 50000  THEN 'Moderate'
      WHEN f.fund_name IS NOT NULL
       AND c.fund_name IS NOT NULL
       AND ABS(COALESCE(f.amount, 0) - COALESCE(c.amount, 0)) >  30000  THEN 'Low'
      ELSE NULL
    END AS variance_bucket,

    -- global counters
    COUNT(*)                    OVER()                                      AS population_count,
    COUNT(*) FILTER (WHERE f.fund_name IS NULL) OVER()                      AS custody_only_count,
    COUNT(*) FILTER (WHERE c.fund_name IS NULL) OVER()                      AS fa_only_count,
    COUNT(*) FILTER (
      WHERE f.fund_name IS NOT NULL
        AND c.fund_name IS NOT NULL
        AND ABS(COALESCE(f.amount, 0) - COALESCE(c.amount, 0)) > 30000
    ) OVER() AS matched_but_different_count

  FROM lux_funds AS f
  FULL OUTER JOIN custody_nav AS c
    ON f.fund_name    = c.fund_name
   AND f.subfund_name = c.subfund_name
   AND f.nav_date     = c.nav_date
) AS q
ORDER BY
  CASE q.status
    WHEN 'Custody_only'                 THEN 1
    WHEN 'FA_only'                      THEN 2
    WHEN 'Matched_but_Different'        THEN 3
    WHEN 'Matched_and_Within_Threshold' THEN 4
    ELSE 5
  END,
  -- stable sort for readability only; preserves provenance in the SELECT above
  COALESCE(q.fa_fund_name,    q.custody_fund_name),
  COALESCE(q.fa_subfund_name, q.custody_subfund_name),
  COALESCE(q.fa_nav_date,     q.custody_nav_date);
```

**Why this is the only complete view**
- Sees missing items on **both** sides and, separately, matched-but-different rows above the same stable thresholds.
- Preserves provenance of keys: you see **which side** supplied each key. `COALESCE` is used only in `ORDER BY` for stable sorting, **not** to mix keys for analysis.
- Produces counters for each class to drive dashboards and SLAs.

---

## Executive rationale and consequences

**Anti-joins are binary on key existence.**  
They cannot detect value differences because once a row on the other side exists, the anti condition (`other_side.key IS NULL`) is false. Any attempt to “add” `a.amount <> b.amount` mixes two incompatible logics and still misses breaks on matched keys.

**Inner-join variance is blind to missing matches.**  
It produces a clean exception list on matched pairs, but if a NAV is unposted on one side, it silently disappears from scope. That is not a “no break” — it is a **missing posting** that must be triaged differently.

**Full outer join is the control-complete baseline.**  
It separates three operational realities in one pass:
1) **FA_only** — likely unposted or upstream feed delay on Custody.  
2) **Custody_only** — the mirror case on FA.  
3) **Matched_but_Different** — true financial differences to investigate with buckets aligned to materiality.

**Operational impact if you use the wrong method**
- **Lost breaks** (inner only): timing/unposted items never hit the queue. Downstream reporting appears “clean” while controls are blind.
- **False narrative** (anti-join only): you escalate missing items but ignore large value differences, misallocating analyst time.
- **SLA risk**: queues balloon with the wrong items or exclude the right ones; cut-offs are missed; NAV publication is delayed.
- **Governance**: audit trails expect explicit logic distinguishing “missing” from “different”. Full outer join provides this split cleanly and reproducibly.
- **Cost and reputation**: repeated governance misses trigger remediation plans, client distrust, and supervisory scrutiny.

**Practical guidance**
- Use the **full outer join** query above as the default control view for daily NAV reconciliation.
- Feed the three classes into separate workflows:  
  FA_only / Custody_only → unposted/timing queue with owner and SLA.  
  Matched_but_Different → investigation queue with materiality buckets.
- Keep thresholds stable and documented. Do **not** use `COALESCE` on keys for analysis — only for safe sorting or display when both sides are shown side-by-side.
