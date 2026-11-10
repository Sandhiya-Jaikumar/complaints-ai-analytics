-- One row per complaint (Sep 2023 - Aug 2026, every product except credit reporting).
-- Types are fixed and text is tidied. Every scope and quality rule from the audit is a yes/no flag:
-- nothing is deleted, so every decision can be counted, explained and reversed.

WITH source AS (
  SELECT * FROM {{ source('raw', 'complaints') }}
),

typed AS (
  SELECT
    SAFE_CAST(complaint_id AS INT64)                         AS complaint_id,
    SAFE.PARSE_DATE('%Y-%m-%d', date_received)               AS date_received,
    SAFE.PARSE_DATE('%Y-%m-%d', date_sent_to_company)        AS date_sent_to_company,
    TRIM(product)                                            AS product,
    TRIM(sub_product)                                        AS sub_product,
    TRIM(issue)                                              AS issue,
    TRIM(sub_issue)                                          AS sub_issue,
    TRIM(company)                                            AS company_name,
    UPPER(TRIM(company))                                     AS company_key,   -- merges spellings like "First Technology..." vs "FIRST TECHNOLOGY..."
    UPPER(TRIM(state))                                       AS state,
    TRIM(zip_code)                                           AS zip_code,
    tags,
    submitted_via,
    company_response_to_consumer                             AS company_response,
    company_public_response,
    timely_response,
    NULLIF(TRIM(consumer_complaint_narrative), '')           AS story,
    source_file
  FROM source
),

-- How many times each exact story text appears in the analysis period (copy-paste campaigns)
story_counts AS (
  SELECT
    story,
    COUNT(*) AS story_copies
  FROM typed
  WHERE story IS NOT NULL
    AND date_received BETWEEN DATE '2024-01-01' AND DATE '2026-06-30'
  GROUP BY story
)

SELECT
  t.*,
  DATE_DIFF(t.date_sent_to_company, t.date_received, DAY)    AS days_to_company,

  -- Scope flags
  COALESCE(t.date_received BETWEEN DATE '2024-01-01' AND DATE '2026-06-30', FALSE) AS is_in_period,
  COALESCE(t.product IN (
    'Credit card',
    'Checking or savings account',
    'Money transfer, virtual currency, or money service',
    'Mortgage',
    'Vehicle loan or lease',
    'Prepaid card'
  ), FALSE)                                                  AS is_in_scope_product,

  -- Response flags ("Untimely response" means the company never answered, so it is NOT closed)
  COALESCE(STARTS_WITH(t.company_response, 'Closed'), FALSE)                     AS is_closed,
  COALESCE(t.company_response = 'Closed with monetary relief', FALSE)            AS is_monetary_relief,
  COALESCE(t.company_response IN ('Closed with monetary relief',
                                  'Closed with non-monetary relief'), FALSE)     AS is_any_relief,
  COALESCE(t.company_response = 'Untimely response', FALSE)                      AS is_no_response,
  COALESCE(t.timely_response = 'Yes', FALSE)                                     AS is_timely,

  -- Story flags
  t.story IS NOT NULL                                        AS has_story,
  COALESCE(sc.story_copies, 0)                               AS story_copies,
  COALESCE(sc.story_copies, 0) > 1                           AS is_copied_story,

  -- Other flags
  COALESCE(t.state IN (
    'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA','KS','KY',
    'LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY','NC','ND',
    'OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY','DC'
  ), FALSE)                                                  AS is_state_or_dc,
  COALESCE(REGEXP_CONTAINS(t.tags, r'Older American'), FALSE) AS is_older_american,
  COALESCE(REGEXP_CONTAINS(t.tags, r'Servicemember'), FALSE)  AS is_servicemember,
-- Credit bureaus: their complaints are credit report disputes even when filed under a bank product
  COALESCE(REGEXP_CONTAINS(t.company_key, r'^(EQUIFAX|TRANSUNION|EXPERIAN)'), FALSE) AS is_credit_bureau

FROM typed AS t
LEFT JOIN story_counts AS sc
  ON t.story = sc.story