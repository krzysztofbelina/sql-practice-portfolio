# Case 01 — STRICT vs MIXED NAV Reconciliation
Use case: detecting NAV mismatches for daily fund reconciliation

## 1) Why `COALESCE` and why **not** with estimates or other dates

**Nulls break arithmetic** → any math with `NULL` returns `NULL`.  
Use `COALESCE(x, 0)` **only** to prevent null propagation in calculations. It does **not** replace missing financial data.

**Why no estimates and no cross-date substitutions in strict controls**

- NAV is struck at a **specific valuation point** under the fund’s valuation policy. Mixing other days or estimates breaches fair-valuation and depositary-oversight rules.  
- Regulatory anchors (illustrative, non-exhaustive):  
  - **UCITS** Art. 22 — depositary duties (oversight of cash flows, ownership verification, and monitoring of NAV procedures).  
  - **AIFMD** Art. 19 — valuation regime for AIFs (independence and consistency of valuation).  
  - **IOSCO** — principles for valuation of CIS (consistency, transparency, and robust controls).  
  - EU/national guidance frequently referenced by practitioners: **ESMA**, **CNMV (Spain)**, **Ganado Advocates (Malta)** technical notes and circulars on valuation/NAV error governance.  
  - **Luxembourg**: historical **CSSF 02/77**; as of **01-Jan-2025, CSSF 24/856** — NAV error regime and correction rules, reinforcing date-accurate valuation and proper error reporting rather than “patching” with estimates.

**Conclusion:**  
- **STRICT**: real `amount` only, same day on both sides.  
- **MIXED**: operational variant that allows `estimated_amount` to demonstrate how fallbacks change exception counts. Not audit-compliant.

---

## 2) SQL — STRICT (no estimates)

```sql
-- STRICT: Real NAV vs Real NAV (audit-compliant)
-- Join: exact triplet (fund_name, subfund_name, nav_date)
-- Filter: absolute difference > 30,000
-- Buckets: absolute-only (stable, materiality-aligned)
-- Window count: exception population size in one pass

SELECT
  f.fund_name,
  f.subfund_name,
  f.nav_date,
  f.amount AS fa_amount,
  c.amount AS custody_amount,
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

---

## 3) SQL — MIXED (with estimates)

```sql
-- MIXED: Allows estimated_amount as explicit fallback (operational view, not audit-compliant)
-- Same join, thresholds, and buckets. Purpose: quantify impact of fallbacks on exception counts.

SELECT
  f.fund_name,
  f.subfund_name,
  f.nav_date,
  f.amount AS fa_amount,
  c.amount AS custody_amount,
  ABS(
    COALESCE(f.amount, f.estimated_amount, 0)
    - COALESCE(c.amount, c.estimated_amount, 0)
  ) AS absolute_difference_threshold_30000,
  CASE
    WHEN ABS(COALESCE(f.amount, f.estimated_amount, 0) - COALESCE(c.amount, c.estimated_amount, 0)) >= 300000 THEN 'Very_High'
    WHEN ABS(COALESCE(f.amount, f.estimated_amount, 0) - COALESCE(c.amount, c.estimated_amount, 0)) >= 200000 THEN 'High'
    WHEN ABS(COALESCE(f.amount, f.estimated_amount, 0) - COALESCE(c.amount, c.estimated_amount, 0)) >= 50000  THEN 'Moderate'
    ELSE 'Low'
  END AS variance_bucket,
  COUNT(*) OVER() AS exception_count
FROM lux_funds AS f
INNER JOIN custody_nav AS c
  ON f.fund_name    = c.fund_name
 AND f.subfund_name = c.subfund_name
 AND f.nav_date     = c.nav_date
WHERE
  ABS(
    COALESCE(f.amount, f.estimated_amount, 0)
    - COALESCE(c.amount, c.estimated_amount, 0)
  ) > 30000
ORDER BY
  absolute_difference_threshold_30000 DESC,
  f.fund_name,
  f.subfund_name,
  f.nav_date;
```

---

## SUMMARY — IMPACT & CONSEQUENCES (STRICT 20 vs MIXED 23)

Key fact:
- STRICT exceptions = 20  
- MIXED exceptions = 23  
- Mixed adds 3 additional exceptions due to estimated fallbacks.

Legal / regulatory consequences  
- NAV integrity breach risk: mixing estimates can be treated as improper valuation practice under UCITS Art.22 and AIFMD Art.19. Regulators (CSSF, ESMA, CNMV, IOSCO guidance) expect date-accurate NAVs and formal NAV error regimes (see CSSF 24/856).  
- Reporting exposure: inflated exception counts may trigger unnecessary NAV error reports or incorrect remedial filings. That increases legal scrutiny and risk of regulatory inquiries.  
- Audit trail weakness: presenting mixed results as “reconciled” undermines depositary oversight and external audit conclusions. Could lead to qualification in audit reports.  
- Potential penalties: material misreporting or repeated NAV errors can lead to fines, required restatements, and formal remediation plans imposed by supervisors.  

Operational / process consequences  
- False positives overhead: +3 extra exceptions equals wasted analyst hours investigating non-material or estimate-driven mismatches.  
- Escalation churn: more exceptions → more tickets → delayed root-cause resolution for real issues.  
- SLA and deadline risk: inflated queue can cause missed reconciliation SLAs, late investor reporting, and delayed NAV publication.  
- Decision noise: dashboards and ops pipelines will prioritize wrong items or dilute focus on real high-severity breaks.  

Financial consequences  
- Direct cost: analyst time (investigation, calls, emails) multiplied by false-positive count.  
- Indirect cost: delayed NAVs can block subscriptions/redemptions, harm liquidity management, and in extreme cases trigger client claims.  
- Reputational cost: repeated governance issues reduce trust from clients, custodians, and auditors.  

Control & governance implications  
- Policy gap: absence of strict source hierarchy or unclear fallback rules leads operations to mix data ad-hoc.  
- Segregation of duties: lack of separate “operational diagnostics” vs “audit truth” pipelines causes mixed results to leak into formal reports.  
- Change management: introducing estimates without governance requires documented approvals, test plans, and audit trail.  

Recommended mitigation (practical steps)  
1. Lock audit pipeline to STRICT logic. Mixed pipeline can run parallel for diagnostics only.  
2. Document fallback policy: when estimates may be used, who approves, and how results are flagged.  
3. Add automated flags in ETL: mark rows using estimated_amount; exclude from audit exports.  
4. Triage rules: auto-filter Low bucket for manual review; escalate Very_High immediately.  
5. Track metrics: record strict_count vs mixed_count daily; alert on divergence threshold (e.g., >10%).  
6. Root-cause workflows: ticket creation, RCA, remediation owner, SLA clock.  
7. Governance: update fund valuation policy & operations manual to reflect decision.  
8. Audit evidence: store query snapshots, parameters, and exception lists per run for external review.  

**Conclusion:** Allowing estimates inflates exceptions, wastes resources, weakens controls, and creates regulatory and audit risk; maintain strict date-accurate NAVs for reporting and run mixed only as a controlled diagnostic layer.
