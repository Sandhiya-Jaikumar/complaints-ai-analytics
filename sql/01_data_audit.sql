-- RUN ORDER 1: run after loading raw.complaints (Step 5). Read-only checks; safe to rerun anytime.
-- All columns are text (STRING); dates are in YYYY-MM-DD format, so they can be compared as text.

-- Query 1: Products in the analysis period (Jan 2024 - Jun 2026), with written-story share
SELECT
  product,
  COUNT(*) AS complaints,
  COUNTIF(consumer_complaint_narrative IS NOT NULL) AS with_story,
  ROUND(100 * COUNTIF(consumer_complaint_narrative IS NOT NULL) / COUNT(*), 1) AS story_pct
FROM `complaints-ai-analytics.raw.complaints`
WHERE date_received BETWEEN '2024-01-01' AND '2026-06-30'
GROUP BY product
ORDER BY complaints DESC;


-- Query 2: Do the dates convert, and are they in a sensible order?
WITH d AS (
  SELECT
    SAFE.PARSE_DATE('%Y-%m-%d', date_received) AS received,
    SAFE.PARSE_DATE('%Y-%m-%d', date_sent_to_company) AS sent,
    date_received, date_sent_to_company
  FROM `complaints-ai-analytics.raw.complaints`
)
SELECT
  COUNT(*) AS rows_checked,
  COUNTIF(received IS NULL) AS received_failed_to_convert,
  COUNTIF(date_sent_to_company IS NULL) AS sent_date_missing,
  COUNTIF(sent IS NULL AND date_sent_to_company IS NOT NULL) AS sent_failed_to_convert,
  COUNTIF(sent < received) AS sent_before_received,
  APPROX_QUANTILES(DATE_DIFF(sent, received, DAY), 100)[OFFSET(50)] AS median_days_to_company,
  APPROX_QUANTILES(DATE_DIFF(sent, received, DAY), 100)[OFFSET(95)] AS p95_days_to_company,
  MAX(DATE_DIFF(sent, received, DAY)) AS max_days_to_company
FROM d;


-- Query 3: Missing values per column (analysis period only)
SELECT
  COUNT(*) AS complaints,
  COUNTIF(sub_product IS NULL) AS missing_sub_product,
  COUNTIF(issue IS NULL) AS missing_issue,
  COUNTIF(sub_issue IS NULL) AS missing_sub_issue,
  COUNTIF(company IS NULL) AS missing_company,
  COUNTIF(state IS NULL) AS missing_state,
  COUNTIF(zip_code IS NULL) AS missing_zip,
  COUNTIF(tags IS NULL) AS missing_tags,
  COUNTIF(submitted_via IS NULL) AS missing_submitted_via,
  COUNTIF(company_response_to_consumer IS NULL) AS missing_company_response,
  COUNTIF(timely_response IS NULL) AS missing_timely,
  COUNTIF(company_public_response IS NULL) AS missing_public_response
FROM `complaints-ai-analytics.raw.complaints`
WHERE date_received BETWEEN '2024-01-01' AND '2026-06-30';


-- Query 4: Company response and timely response values (what do the categories look like?)
SELECT
  company_response_to_consumer,
  timely_response,
  COUNT(*) AS complaints
FROM `complaints-ai-analytics.raw.complaints`
WHERE date_received BETWEEN '2024-01-01' AND '2026-06-30'
GROUP BY 1, 2
ORDER BY complaints DESC;


-- Query 5: The January 2025 spike - which companies? (Dec 2024 vs Jan 2025 vs Feb 2025)
SELECT
  company,
  COUNTIF(date_received BETWEEN '2024-12-01' AND '2024-12-31') AS dec_2024,
  COUNTIF(date_received BETWEEN '2025-01-01' AND '2025-01-31') AS jan_2025,
  COUNTIF(date_received BETWEEN '2025-02-01' AND '2025-02-28') AS feb_2025
FROM `complaints-ai-analytics.raw.complaints`
WHERE date_received BETWEEN '2024-12-01' AND '2025-02-28'
GROUP BY company
ORDER BY jan_2025 DESC
LIMIT 15;


-- Query 6: The January 2025 spike - which products and issues?
SELECT
  product,
  issue,
  COUNTIF(date_received BETWEEN '2024-12-01' AND '2024-12-31') AS dec_2024,
  COUNTIF(date_received BETWEEN '2025-01-01' AND '2025-01-31') AS jan_2025,
  COUNTIF(date_received BETWEEN '2025-02-01' AND '2025-02-28') AS feb_2025
FROM `complaints-ai-analytics.raw.complaints`
WHERE date_received BETWEEN '2024-12-01' AND '2025-02-28'
GROUP BY product, issue
ORDER BY jan_2025 DESC
LIMIT 15;


-- Query 7: Written stories - length, privacy redactions ("XXXX"), and copy-paste duplicates
SELECT
  COUNT(*) AS stories,
  COUNT(DISTINCT consumer_complaint_narrative) AS distinct_stories,
  COUNT(*) - COUNT(DISTINCT consumer_complaint_narrative) AS repeated_story_texts,
  APPROX_QUANTILES(LENGTH(consumer_complaint_narrative), 100)[OFFSET(50)] AS median_characters,
  MIN(LENGTH(consumer_complaint_narrative)) AS shortest,
  MAX(LENGTH(consumer_complaint_narrative)) AS longest,
  COUNTIF(LENGTH(consumer_complaint_narrative) < 50) AS under_50_characters,
  COUNTIF(REGEXP_CONTAINS(consumer_complaint_narrative, r'XX')) AS with_redactions
FROM `complaints-ai-analytics.raw.complaints`
WHERE date_received BETWEEN '2024-01-01' AND '2026-06-30'
  AND consumer_complaint_narrative IS NOT NULL;


-- Query 8: Companies and states - how many, and any odd state values?
SELECT
  COUNT(DISTINCT company) AS companies,
  COUNT(DISTINCT state) AS state_values,
  COUNTIF(state IS NOT NULL AND LENGTH(state) != 2) AS odd_state_values,
  STRING_AGG(DISTINCT IF(LENGTH(state) != 2, state, NULL), ', ' LIMIT 10) AS examples_of_odd_states
FROM `complaints-ai-analytics.raw.complaints`
WHERE date_received BETWEEN '2024-01-01' AND '2026-06-30';

-- Query 9: January 2025 day by day for the four spike companies (did the jumps follow the news dates?)
SELECT
  date_received,
  COUNTIF(company = 'Block, Inc.') AS block_cash_app,
  COUNTIF(company LIKE 'Early Warning%') AS zelle_operator,
  COUNTIF(company LIKE 'CAPITAL ONE%') AS capital_one,
  COUNTIF(company = 'NAVY FEDERAL CREDIT UNION') AS navy_federal
FROM `complaints-ai-analytics.raw.complaints`
WHERE date_received BETWEEN '2025-01-01' AND '2025-01-31'
GROUP BY date_received
ORDER BY date_received;


-- Query 10: The most copy-pasted stories (how many copies, which product and companies, which dates)
SELECT
  LEFT(consumer_complaint_narrative, 150) AS story_start,
  COUNT(*) AS copies,
  COUNT(DISTINCT company) AS companies,
  ANY_VALUE(product) AS example_product,
  MIN(date_received) AS first_seen,
  MAX(date_received) AS last_seen
FROM `complaints-ai-analytics.raw.complaints`
WHERE date_received BETWEEN '2024-01-01' AND '2026-06-30'
  AND consumer_complaint_narrative IS NOT NULL
GROUP BY consumer_complaint_narrative
HAVING COUNT(*) > 1
ORDER BY copies DESC
LIMIT 15;


-- Query 11: How much copy-pasting is there in each product?
WITH copies AS (
  SELECT consumer_complaint_narrative, COUNT(*) AS n
  FROM `complaints-ai-analytics.raw.complaints`
  WHERE date_received BETWEEN '2024-01-01' AND '2026-06-30'
    AND consumer_complaint_narrative IS NOT NULL
  GROUP BY consumer_complaint_narrative
)
SELECT
  r.product,
  COUNT(*) AS stories,
  COUNTIF(c.n > 1) AS stories_that_are_copies,
  ROUND(100 * COUNTIF(c.n > 1) / COUNT(*), 1) AS copy_pct
FROM `complaints-ai-analytics.raw.complaints` AS r
JOIN copies AS c USING (consumer_complaint_narrative)
WHERE r.date_received BETWEEN '2024-01-01' AND '2026-06-30'
GROUP BY r.product
ORDER BY copy_pct DESC;


-- Query 12: Company names written in more than one way (e.g. different capitals or extra spaces)
SELECT
  UPPER(TRIM(company)) AS company_key,
  COUNT(DISTINCT company) AS spellings,
  STRING_AGG(DISTINCT company, ' | ') AS examples,
  COUNT(*) AS complaints
FROM `complaints-ai-analytics.raw.complaints`
WHERE date_received BETWEEN '2024-01-01' AND '2026-06-30'
GROUP BY company_key
HAVING COUNT(DISTINCT company) > 1
ORDER BY complaints DESC
LIMIT 20;