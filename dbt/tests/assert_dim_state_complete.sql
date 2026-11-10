-- dim_state must have all 50 states plus DC, and every in-state complaint must find its population.
-- Catches problems like the leading-zero state code issue. Passes when this returns zero rows.

WITH checks AS (
  SELECT
    (SELECT COUNT(*) FROM {{ ref('dim_state') }}) AS states,
    (SELECT COUNT(*)
       FROM {{ ref('fct_complaints') }} AS f
       LEFT JOIN {{ ref('dim_state') }} AS s
         ON f.state = s.state_code
      WHERE f.is_state_or_dc
        AND s.state_code IS NULL)                 AS complaints_without_population
)

SELECT *
FROM checks
WHERE states != 51
   OR complaints_without_population > 0