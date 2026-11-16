-- Exec Q3: What are customers actually complaining about?
-- Source: dbt_sandhiya.fct_complaint_themes = 900 AI-labeled stories (150 per product),
-- weighted up to all 308,826 individual (non-copied) stories. Theme accuracy ~69% (held-out test);
-- "Customer service failure" is under-counted by the AI (about 2.5x).

-- Query 1: Theme mix across all six products (weighted)
SELECT
  ai_theme,
  COUNT(*) AS sampled_stories,
  ROUND(SUM(sample_weight)) AS estimated_stories,
  ROUND(100 * SUM(sample_weight) / SUM(SUM(sample_weight)) OVER (), 1) AS pct_of_stories
FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaint_themes`
GROUP BY ai_theme
ORDER BY estimated_stories DESC;

-- Query 2: Top 3 themes within each product (150 stories per product)
SELECT
  product,
  ai_theme,
  COUNT(*) AS sampled_stories,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY product), 1) AS pct_within_product
FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaint_themes`
GROUP BY product, ai_theme
QUALIFY ROW_NUMBER() OVER (PARTITION BY product ORDER BY COUNT(*) DESC) <= 3
ORDER BY product, sampled_stories DESC;

-- Query 3: Which problems get consumers money back? (weighted, closed complaints only)
SELECT
  ai_theme,
  COUNT(*) AS sampled_stories,
  ROUND(100 * SUM(IF(is_monetary_relief, sample_weight, 0)) / NULLIF(SUM(IF(is_closed, sample_weight, 0)), 0), 1) AS money_back_pct,
  ROUND(100 * SUM(IF(is_any_relief, sample_weight, 0)) / NULLIF(SUM(IF(is_closed, sample_weight, 0)), 0), 1) AS any_relief_pct
FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaint_themes`
GROUP BY ai_theme
ORDER BY money_back_pct DESC;

-- Query 4: Theme mix by year (weighted share of each year's stories; small samples, read as direction only)
WITH y AS (
  SELECT ai_theme, EXTRACT(YEAR FROM date_received) AS yr, sample_weight
  FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaint_themes`
)
SELECT
  ai_theme,
  COUNTIF(yr = 2024) AS n_2024,
  COUNTIF(yr = 2025) AS n_2025,
  COUNTIF(yr = 2026) AS n_2026_h1,
  ROUND(100 * SUM(IF(yr = 2024, sample_weight, 0)) / SUM(SUM(IF(yr = 2024, sample_weight, 0))) OVER (), 1) AS pct_2024,
  ROUND(100 * SUM(IF(yr = 2025, sample_weight, 0)) / SUM(SUM(IF(yr = 2025, sample_weight, 0))) OVER (), 1) AS pct_2025,
  ROUND(100 * SUM(IF(yr = 2026, sample_weight, 0)) / SUM(SUM(IF(yr = 2026, sample_weight, 0))) OVER (), 1) AS pct_2026_h1
FROM y
GROUP BY ai_theme
ORDER BY pct_2026_h1 DESC;

-- Query 5: What the AI adds - one AI theme spans many CFPB issue categories (example: Fraud)
SELECT
  product,
  issue,
  COUNT(*) AS sampled_stories
FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaint_themes`
WHERE ai_theme = 'Fraud or unauthorized transaction'
GROUP BY product, issue
ORDER BY sampled_stories DESC
LIMIT 12;