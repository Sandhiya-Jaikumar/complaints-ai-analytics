-- RUN ORDER 5: run after dbt build. Answers Exec Question 2: how well do companies respond, and how often do consumers get money back?
-- Rates use closed complaints (response starts with "Closed"); "Untimely response" = the company never answered.

-- Query 1: Response quality by product
SELECT
  IF(GROUPING(product) = 1, 'ALL 6 PRODUCTS', product) AS product_group,
  COUNT(*) AS complaints,
  ROUND(100 * COUNTIF(is_timely) / COUNT(*), 1) AS timely_pct,
  COUNTIF(is_no_response) AS never_answered,
  COUNTIF(is_closed) AS closed,
  ROUND(100 * COUNTIF(is_monetary_relief) / COUNTIF(is_closed), 1) AS monetary_relief_pct,
  ROUND(100 * COUNTIF(is_any_relief) / COUNTIF(is_closed), 1) AS any_relief_pct
FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints`
GROUP BY ROLLUP(product)
ORDER BY complaints DESC;


-- Query 2: Are responses getting better or worse? (by quarter)
SELECT
  DATE_TRUNC(date_received, QUARTER) AS quarter,
  COUNT(*) AS complaints,
  ROUND(100 * COUNTIF(is_timely) / COUNT(*), 1) AS timely_pct,
  COUNTIF(is_no_response) AS never_answered,
  ROUND(100 * COUNTIF(is_monetary_relief) / COUNTIF(is_closed), 1) AS monetary_relief_pct,
  ROUND(100 * COUNTIF(is_any_relief) / COUNTIF(is_closed), 1) AS any_relief_pct
FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints`
GROUP BY quarter
ORDER BY quarter;


-- Query 3: Which issues most often end with money back? (at least 1,000 closed complaints)
SELECT
  product,
  issue,
  COUNTIF(is_closed) AS closed,
  COUNTIF(is_monetary_relief) AS monetary_relief,
  ROUND(100 * COUNTIF(is_monetary_relief) / COUNTIF(is_closed), 1) AS monetary_relief_pct,
  ROUND(100 * COUNTIF(is_monetary_relief) / SUM(COUNTIF(is_monetary_relief)) OVER (), 1) AS share_of_all_money_back_pct
FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints`
GROUP BY product, issue
HAVING COUNTIF(is_closed) >= 1000
ORDER BY monetary_relief_pct DESC
LIMIT 15;


-- Query 4: The 15 largest companies - how well do they respond?
WITH top_companies AS (
  SELECT company_key
  FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints`
  GROUP BY company_key
  ORDER BY COUNT(*) DESC
  LIMIT 15
)
SELECT
  d.company_name,
  COUNT(*) AS complaints,
  ROUND(100 * COUNTIF(f.is_timely) / COUNT(*), 1) AS timely_pct,
  COUNTIF(f.is_no_response) AS never_answered,
  ROUND(100 * COUNTIF(f.is_monetary_relief) / COUNTIF(f.is_closed), 1) AS monetary_relief_pct,
  ROUND(100 * COUNTIF(f.is_any_relief) / COUNTIF(f.is_closed), 1) AS any_relief_pct
FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints` AS f
JOIN top_companies AS t
  ON f.company_key = t.company_key
JOIN `complaints-ai-analytics.dbt_sandhiya.dim_company` AS d
  ON f.company_key = d.company_key
GROUP BY d.company_name
ORDER BY monetary_relief_pct DESC;


-- Query 5: Companies that most often never answered (at least 500 complaints)
SELECT
  d.company_name,
  COUNT(*) AS complaints,
  COUNTIF(f.is_no_response) AS never_answered,
  ROUND(100 * COUNTIF(f.is_no_response) / COUNT(*), 1) AS never_answered_pct,
  ROUND(100 * COUNTIF(f.is_timely) / COUNT(*), 1) AS timely_pct
FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints` AS f
JOIN `complaints-ai-analytics.dbt_sandhiya.dim_company` AS d
  ON f.company_key = d.company_key
GROUP BY d.company_name
HAVING COUNT(*) >= 500
ORDER BY never_answered_pct DESC
LIMIT 10;


-- Query 6: Do copy-pasted template complaints get the same outcome as individual stories?
SELECT
  CASE
    WHEN NOT has_story THEN 'No written story'
    WHEN is_copied_story THEN 'Copy-pasted template story'
    ELSE 'Individual written story'
  END AS story_type,
  COUNT(*) AS complaints,
  ROUND(100 * COUNTIF(is_monetary_relief) / COUNTIF(is_closed), 1) AS monetary_relief_pct,
  ROUND(100 * COUNTIF(is_any_relief) / COUNTIF(is_closed), 1) AS any_relief_pct,
  ROUND(100 * COUNTIF(is_timely) / COUNT(*), 1) AS timely_pct
FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints`
GROUP BY story_type
ORDER BY complaints DESC;


-- Query 7: Fair comparison - CREDIT CARD complaints only, the 10 largest card companies
-- (removes the product-mix effect from the company comparison)
WITH top_card AS (
  SELECT company_key
  FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints`
  WHERE product = 'Credit card'
  GROUP BY company_key
  ORDER BY COUNT(*) DESC
  LIMIT 10
)
SELECT
  d.company_name,
  COUNT(*) AS card_complaints,
  ROUND(100 * COUNTIF(f.is_monetary_relief) / COUNTIF(f.is_closed), 1) AS monetary_relief_pct,
  ROUND(100 * COUNTIF(f.is_any_relief) / COUNTIF(f.is_closed), 1) AS any_relief_pct,
  ROUND(100 * COUNTIF(f.issue = 'Problem with a purchase shown on your statement') / COUNT(*), 1) AS purchase_dispute_share_pct
FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints` AS f
JOIN top_card AS t
  ON f.company_key = t.company_key
JOIN `complaints-ai-analytics.dbt_sandhiya.dim_company` AS d
  ON f.company_key = d.company_key
WHERE f.product = 'Credit card'
GROUP BY d.company_name
ORDER BY monetary_relief_pct DESC;


-- Query 8: Which products do the slowest responders handle? (Conduent and Shellpoint)
SELECT
  d.company_name,
  f.product,
  COUNT(*) AS complaints,
  ROUND(100 * COUNTIF(f.is_timely) / COUNT(*), 1) AS timely_pct,
  COUNTIF(f.is_no_response) AS never_answered
FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints` AS f
JOIN `complaints-ai-analytics.dbt_sandhiya.dim_company` AS d
  ON f.company_key = d.company_key
WHERE d.company_name LIKE 'Conduent%'
   OR d.company_name LIKE 'Shellpoint%'
GROUP BY d.company_name, f.product
ORDER BY complaints DESC;