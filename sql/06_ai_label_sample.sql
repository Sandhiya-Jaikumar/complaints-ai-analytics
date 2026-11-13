-- RUN ORDER 6: 102 written stories for the human answer key (17 per product).
-- Reproducible random sample (FARM_FINGERPRINT), copy-paste templates excluded.
-- The CFPB issue and the company are hidden on purpose, so the human labels aren't influenced by them.

WITH pool AS (
  SELECT
    complaint_id,
    product,
    story,
    ROW_NUMBER() OVER (
      PARTITION BY product
      ORDER BY FARM_FINGERPRINT(CAST(complaint_id AS STRING))
    ) AS rn
  FROM `complaints-ai-analytics.dbt_sandhiya.stg_complaints`
  WHERE is_in_period
    AND is_in_scope_product
    AND has_story
    AND NOT is_copied_story
)

SELECT
  complaint_id,
  product,
  story,
  '' AS my_theme,
  '' AS my_notes
FROM pool
WHERE rn <= 17
ORDER BY FARM_FINGERPRINT(CONCAT('label-', CAST(complaint_id AS STRING)))