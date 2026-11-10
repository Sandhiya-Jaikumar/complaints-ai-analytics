-- One row per complaint in the analysis: received Jan 1, 2024 - Jun 30, 2026, in the 6 bank and payments products.
-- Story text is left out (it stays in staging) so this table is small and fast for BI tools and the AI assistant.

SELECT
  complaint_id,
  date_received,
  DATE_TRUNC(date_received, MONTH)   AS month,
  date_sent_to_company,
  days_to_company,
  company_key,
  product,
  sub_product,
  issue,
  sub_issue,
  state,
  submitted_via,
  company_response,
  timely_response,
  is_closed,
  is_monetary_relief,
  is_any_relief,
  is_no_response,
  is_timely,
  has_story,
  is_copied_story,
  story_copies,
  is_state_or_dc,
  is_older_american,
  is_servicemember,
  is_credit_bureau
FROM {{ ref('stg_complaints') }}
WHERE is_in_period
  AND is_in_scope_product