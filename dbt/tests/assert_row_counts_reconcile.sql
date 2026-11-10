-- Row counts must reconcile across layers. The test passes when this returns zero rows.
-- raw = staging (nothing lost), fact = staging analysis rows, every fact row counted once in dim_company.

WITH counts AS (
  SELECT
    (SELECT COUNT(*) FROM {{ source('raw', 'complaints') }})                                AS raw_rows,
    (SELECT COUNT(*) FROM {{ ref('stg_complaints') }})                                      AS staging_rows,
    (SELECT COUNTIF(is_in_period AND is_in_scope_product) FROM {{ ref('stg_complaints') }}) AS staging_analysis_rows,
    (SELECT COUNT(*) FROM {{ ref('fct_complaints') }})                                      AS fact_rows,
    (SELECT SUM(complaints) FROM {{ ref('dim_company') }})                                  AS dim_company_complaints
)

SELECT *
FROM counts
WHERE raw_rows != staging_rows
   OR staging_analysis_rows != fact_rows
   OR fact_rows != dim_company_complaints