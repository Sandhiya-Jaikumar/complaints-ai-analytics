-- Staging checks: counts must match the raw table and the audit
SELECT
  COUNT(*)                                                         AS all_rows,
  COUNT(DISTINCT complaint_id)                                     AS unique_ids,
  COUNTIF(date_received IS NULL)                                   AS bad_dates,
  COUNTIF(is_in_period)                                            AS in_period,
  COUNTIF(is_in_period AND is_in_scope_product)                    AS analysis_rows,
  COUNTIF(is_in_period AND is_in_scope_product AND has_story)      AS analysis_stories,
  COUNTIF(is_in_period AND is_in_scope_product AND is_copied_story) AS analysis_copied_stories,
  COUNTIF(is_in_period AND is_in_scope_product AND is_closed)      AS analysis_closed,
  COUNTIF(is_in_period AND is_in_scope_product AND is_no_response) AS analysis_no_response,
  COUNT(DISTINCT company_name)                                     AS company_spellings,
  COUNT(DISTINCT company_key)                                      AS companies_after_merge
FROM `complaints-ai-analytics.dbt_sandhiya.stg_complaints`