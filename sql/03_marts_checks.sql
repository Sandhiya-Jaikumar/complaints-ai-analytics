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

-- dim_state checks: 51 rows (50 states + DC), sensible total population, and every state complaint finds its state
SELECT
  (SELECT COUNT(*) FROM `complaints-ai-analytics.dbt_sandhiya.dim_state`)        AS states,
  (SELECT SUM(population) FROM `complaints-ai-analytics.dbt_sandhiya.dim_state`) AS total_population,
  (SELECT COUNT(*) FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints` f
     LEFT JOIN `complaints-ai-analytics.dbt_sandhiya.dim_state` s ON f.state = s.state_code
     WHERE f.is_state_or_dc AND s.state_code IS NULL)                             AS state_complaints_without_population,
  (SELECT COUNTIF(NOT is_state_or_dc) FROM `complaints-ai-analytics.dbt_sandhiya.fct_complaints`) AS complaints_outside_states