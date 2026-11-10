-- RUN ORDER 4: run after dbt build. Answers Exec Question 1: which complaint problems are growing, and for which products?
-- Every growth number is shown twice: all complaints, and excluding copy-pasted template stories.

-- Query 1: Complaints by product - full year 2024 vs 2025, and first half 2025 vs first half 2026
SELECT
  IF(GROUPING(product) = 1, 'ALL 6 PRODUCTS', product) AS product_group,
  COUNTIF(EXTRACT(YEAR FROM date_received) = 2024) AS y2024,
  COUNTIF(EXTRACT(YEAR FROM date_received) = 2025) AS y2025,
  ROUND(100 * (SAFE_DIVIDE(COUNTIF(EXTRACT(YEAR FROM date_received) = 2025),
                           COUNTIF(EXTRACT(YEAR FROM date_received) = 2024)) - 1), 1) AS growth_pct,
  ROUND(100 * (SAFE_DIVIDE(COUNTIF(EXTRACT(YEAR FROM date_received) = 2025 AND NOT is_copied_story),
                           COUNTIF(EXTRACT(YEAR FROM date_received) = 2024 AND NOT is_copied_story)) - 1), 1) AS growth_pct_excl_copies,
  COUNTIF(date_received BETWEEN '2025-01-01' AND '2025-06-30') AS h1_2025,
  COUNTIF(date_received BETWEEN '2026-01-01' AND '2026-06-30') AS h1_2026,
  ROUND(100 * (SAFE_DIVIDE(COUNTIF(date_received BETWEEN '2026-01-01' AND '2026-06-30'),
                           COUNTIF(date_received BETWEEN '2025-01-01' AND '2025-06-30')) - 1), 1) AS h1_growth_pct,
  ROUND(100 * (SAFE_DIVIDE(COUNTIF(date_received BETWEEN '2026-01-01' AND '2026-06-30' AND NOT is_copied_story),
                           COUNTIF(date_received BETWEEN '2025-01-01' AND '2025-06-30' AND NOT is_copied_story)) - 1), 1) AS h1_growth_pct_excl_copies
FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints`
GROUP BY ROLLUP(product)
ORDER BY y2025 DESC;


-- Query 2: The 15 issues that grew the most from 2024 to 2025 (excluding copy-pasted stories)
WITH by_issue AS (
  SELECT
    product,
    issue,
    COUNTIF(EXTRACT(YEAR FROM date_received) = 2024 AND NOT is_copied_story) AS y2024,
    COUNTIF(EXTRACT(YEAR FROM date_received) = 2025 AND NOT is_copied_story) AS y2025,
    COUNTIF(date_received BETWEEN '2025-01-01' AND '2025-06-30' AND NOT is_copied_story) AS h1_2025,
    COUNTIF(date_received BETWEEN '2026-01-01' AND '2026-06-30' AND NOT is_copied_story) AS h1_2026
  FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints`
  GROUP BY product, issue
)
SELECT
  product,
  issue,
  y2024,
  y2025,
  y2025 - y2024 AS added_complaints,
  ROUND(100 * (SAFE_DIVIDE(y2025, y2024) - 1), 1) AS growth_pct,
  h1_2025,
  h1_2026,
  ROUND(100 * (SAFE_DIVIDE(h1_2026, h1_2025) - 1), 1) AS h1_growth_pct
FROM by_issue
WHERE y2025 >= 1000
ORDER BY added_complaints DESC
LIMIT 15;


-- Query 3: The same issues with copy-pasted stories INCLUDED (to see where campaigns change the picture)
SELECT
  product,
  issue,
  COUNTIF(EXTRACT(YEAR FROM date_received) = 2024) AS y2024,
  COUNTIF(EXTRACT(YEAR FROM date_received) = 2025) AS y2025,
  COUNTIF(EXTRACT(YEAR FROM date_received) = 2025) - COUNTIF(EXTRACT(YEAR FROM date_received) = 2024) AS added_complaints,
  COUNTIF(EXTRACT(YEAR FROM date_received) = 2025 AND is_copied_story) AS copied_in_2025
FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints`
GROUP BY product, issue
HAVING y2025 >= 1000
ORDER BY added_complaints DESC
LIMIT 15;


-- Query 4: Monthly trend (for a chart): all complaints vs excluding copy-pasted stories
SELECT
  month,
  COUNT(*) AS complaints,
  COUNTIF(NOT is_copied_story) AS complaints_excl_copies,
  COUNTIF(is_copied_story) AS copied_story_complaints
FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints`
GROUP BY month
ORDER BY month;


-- Query 5: The 15 companies with the most complaints, their share, and their growth
WITH by_company AS (
  SELECT
    company_key,
    COUNT(*) AS complaints,
    COUNTIF(EXTRACT(YEAR FROM date_received) = 2024) AS y2024,
    COUNTIF(EXTRACT(YEAR FROM date_received) = 2025) AS y2025,
    COUNTIF(is_copied_story) AS copied_story_complaints
  FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints`
  GROUP BY company_key
)
SELECT
  d.company_name,
  b.complaints,
  ROUND(100 * b.complaints / SUM(b.complaints) OVER (), 1) AS share_pct,
  ROUND(100 * SUM(b.complaints) OVER (ORDER BY b.complaints DESC) / SUM(b.complaints) OVER (), 1) AS cumulative_share_pct,
  b.y2024,
  b.y2025,
  ROUND(100 * (SAFE_DIVIDE(b.y2025, b.y2024) - 1), 1) AS growth_pct,
  b.copied_story_complaints
FROM by_company AS b
JOIN `complaints-ai-analytics.dbt_sandhiya.dim_company` AS d
  ON b.company_key = d.company_key
ORDER BY b.complaints DESC
LIMIT 15;


-- Query 6: Complaints per 100,000 residents by state (2025, excluding copy-pasted stories)
SELECT
  s.state_code,
  s.state_name,
  COUNTIF(EXTRACT(YEAR FROM f.date_received) = 2025 AND NOT f.is_copied_story) AS complaints_2025,
  ROUND(100000 * COUNTIF(EXTRACT(YEAR FROM f.date_received) = 2025 AND NOT f.is_copied_story) / s.population, 1) AS per_100k_residents
FROM `complaints-ai-analytics.dbt_sandhiya.dim_state` AS s
LEFT JOIN `complaints-ai-analytics.dbt_sandhiya.fct_complaints` AS f
  ON f.state = s.state_code
GROUP BY s.state_code, s.state_name, s.population
ORDER BY per_100k_residents DESC;


-- Query 7: Context - how big is credit reporting compared with everything else? (all products, from the monthly summary)
SELECT
  SUBSTR(month, 1, 4) AS year,
  SUM(complaints) AS all_products,
  SUM(IF(STARTS_WITH(product, 'Credit reporting'), complaints, 0)) AS credit_reporting,
  ROUND(100 * SUM(IF(STARTS_WITH(product, 'Credit reporting'), complaints, 0)) / SUM(complaints), 1) AS credit_reporting_pct
FROM `complaints-ai-analytics.raw.complaints_monthly_all_products`
WHERE month BETWEEN '2024-01' AND '2026-06'
GROUP BY year
ORDER BY year;