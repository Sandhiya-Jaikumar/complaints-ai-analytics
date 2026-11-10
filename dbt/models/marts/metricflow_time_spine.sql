-- Daily calendar MetricFlow uses to roll metrics up to week, month, quarter and year.
SELECT d AS date_day
FROM UNNEST(GENERATE_DATE_ARRAY(DATE '2020-01-01', DATE '2030-12-31')) AS d