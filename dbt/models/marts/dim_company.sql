-- One row per company (after merging spellings). The display name is the company's most common spelling.

WITH spellings AS (
  SELECT
    company_key,
    company_name,
    COUNT(*) AS n
  FROM {{ ref('stg_complaints') }}
  WHERE is_in_period
    AND is_in_scope_product
  GROUP BY company_key, company_name
),

names AS (
  SELECT
    company_key,
    ARRAY_AGG(company_name ORDER BY n DESC, company_name LIMIT 1)[OFFSET(0)] AS company_name
  FROM spellings
  GROUP BY company_key
)

SELECT
  f.company_key,
  n.company_name,
  COUNT(*)                     AS complaints,
  COUNT(DISTINCT f.product)    AS products,
  MIN(f.date_received)         AS first_complaint_date,
  MAX(f.date_received)         AS last_complaint_date
FROM {{ ref('fct_complaints') }} AS f
JOIN names AS n
  ON f.company_key = n.company_key
GROUP BY f.company_key, n.company_name