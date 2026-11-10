-- One row per U.S. state plus DC, with population, for "complaints per 100,000 residents".
-- Population: U.S. Census ACS 2021 1-year estimate (newest state table in BigQuery public data).
-- State IDs are compared as numbers because one source writes "06" and the other may write "6".

WITH population AS (
  SELECT
    SAFE_CAST(geo_id AS INT64)            AS state_fips,
    CAST(total_pop AS INT64)              AS population
  FROM {{ source('census', 'state_2021_1yr') }}
),

state_codes AS (
  SELECT
    SAFE_CAST(state_fips_code AS INT64)   AS state_fips,
    state                                 AS state_code,
    state_name
  FROM {{ source('geo', 'states') }}
)

SELECT
  s.state_code,
  s.state_name,
  p.population
FROM state_codes AS s
JOIN population AS p
  ON s.state_fips = p.state_fips
WHERE s.state_code IN (
  'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA','KS','KY',
  'LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY','NC','ND',
  'OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY','DC'
)