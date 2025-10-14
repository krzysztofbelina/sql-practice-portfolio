-- Case Study: Fund/Subfund normalization match across FA vs Custody
-- Objective: Produce a clean, comparable view of fund/subfund pairs where FA (lux_funds) and Custody (custody_nav)
-- align on normalized names and date. Demonstrates normalization, join discipline, and DQ filters.
SELECT
	UPPER(TRIM(REPLACE(f.fund_name, '_', ' '))) AS normalized_fund_name,
	UPPER(TRIM(REPLACE(f.subfund_name, '2', ' '))) AS normalized_subfund_name,
	f.nav_date,
	CONCAT(f.fund_name, ' - ', f.subfund_name) AS original_label,
	LEFT(f.subfund_name, 2) AS prefix_2,
	RIGHT(f.subfund_name, 2) AS suffix_2,
	LENGTH(f.subfund_name) AS subfund_name_length,
	LOWER(f.fund_name) AS fund_name_lower
FROM lux_funds AS f
JOIN custody_nav AS c
ON UPPER(TRIM(REPLACE(f.fund_name, '_', ' '))) = UPPER(TRIM(REPLACE(c.fund_name, '_', ' ')))
AND UPPER(TRIM(REPLACE(f.subfund_name, '2', ' '))) = UPPER(TRIM(REPLACE(c.subfund_name, '2', ' ')))
AND f.nav_date = c.nav_date
WHERE 
	TRIM(f.subfund_name) <> ' ' 
	AND TRIM(c.subfund_name) <> ' '
ORDER BY 
	normalized_fund_name ASC,
	normalized_subfund_name ASC, 
	f.nav_date ASC;
