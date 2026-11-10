-- One row per day in the analysis period (Jan 1, 2024 - Jun 30, 2026), for trends by month, quarter and year.

SELECT
  d                                        AS date_day,
  DATE_TRUNC(d, MONTH)                     AS month,
  FORMAT_DATE('%b %Y', d)                  AS month_label,
  DATE_TRUNC(d, QUARTER)                   AS quarter,
  CONCAT(CAST(EXTRACT(YEAR FROM d) AS STRING), ' Q', CAST(EXTRACT(QUARTER FROM d) AS STRING)) AS quarter_label,
  EXTRACT(YEAR FROM d)                     AS year,
  EXTRACT(MONTH FROM d)                    AS month_number,
  FORMAT_DATE('%A', d)                     AS weekday_name
FROM UNNEST(GENERATE_DATE_ARRAY(DATE '2024-01-01', DATE '2026-06-30')) AS d