This section contains SQL tasks and datasets based on **real-world fund operations and reconciliation scenarios**.  
Each task represents a realistic operational challenge inspired by daily processes in investment fund administration,  
including NAV control, custody vs FA comparison, and exception identification.

All examples are based on the tables `lux_funds` and `custody_nav`, which simulate the data used in financial operations teams.

---

## 💼 Purpose

To reproduce real reconciliation and fund data quality checks using SQL only.  
These cases combine multiple skills already learned in previous sections — filtering, aggregation, conditional logic,  
JOIN operations, and NULL handling — and apply them in practical financial contexts.

---

## ⚙️ Dataset Description

| Table | Description | Key Columns |
|--------|--------------|-------------|
| **lux_funds** | Represents the Fund Accounting source with NAV and valuation data. | `fund_name`, `subfund_name`, `nav_date`, `account_number`, `amount`, `estimated_amount`, `previous_amount` |
| **custody_nav** | Represents Custody Bank source data used for reconciliation. | `fund_name`, `subfund_name`, `nav_date`, `account_number`, `amount`, `estimated_amount`, `previous_amount` |

---

## 🧾 Notes

- All data in these examples is **synthetic** and was artificially generated for educational and portfolio purposes.  
- The naming convention reflects **real terminology** used in fund operations (BNP Paribas, Deloitte, EY, etc.),  
  but **does not represent real clients or financial data**.  
- Each query was validated to return **non-empty and logically consistent results**.


---

## 🧠 Goal

The goal of this section is to demonstrate **SQL-driven reconciliation capability** — the ability to find, explain,  
and document valuation differences between financial sources without relying on Excel or automation tools.  
This approach mirrors how reconciliation analysts and fund operations teams work with production data in investment banks.

---

