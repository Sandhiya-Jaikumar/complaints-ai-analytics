-- Marts checks: the fact table must match staging exactly; dimensions must cover every fact row
SELECT
  (SELECT COUNT(*) FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints`)                       AS fact_rows,
  (SELECT COUNT(DISTINCT complaint_id) FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints`)    AS fact_unique_ids,
  (SELECT COUNTIF(has_story) FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints`)             AS fact_stories,
  (SELECT COUNT(*) FROM `complaints-ai-analytics.dbt_sandhiya.dim_company`)                          AS companies,
  (SELECT SUM(complaints) FROM `complaints-ai-analytics.dbt_sandhiya.dim_company`)                   AS complaints_in_dim_company,
  (SELECT COUNT(*) FROM `complaints-ai-analytics.dbt_sandhiya.dim_date`)                             AS days_in_dim_date,
  (SELECT COUNT(*) FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints` f
     LEFT JOIN `complaints-ai-analytics.dbt_sandhiya.dim_date` d ON f.date_received = d.date_day
     WHERE d.date_day IS NULL)                                                                         AS facts_without_a_date_row