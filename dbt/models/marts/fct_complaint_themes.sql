-- AI theme for a stratified random sample of 900 complaint stories (150 per product).
-- sample_weight scales each product's sample up to all individual (non-copied) stories in that product.
WITH themes AS (
    SELECT
        CAST(complaint_id AS STRING) AS complaint_id,
        ai_theme,
        model,
        prompt_version,
        labeled_on
    FROM {{ source('ai', 'ai_complaint_themes') }}
),

population AS (
    SELECT product, COUNT(*) AS population_stories
    FROM {{ ref('stg_complaints') }}
    WHERE is_in_period AND is_in_scope_product AND has_story AND NOT is_copied_story
    GROUP BY product
),

joined AS (
    SELECT
        f.*,
        t.ai_theme,
        t.model AS ai_model,
        t.prompt_version AS ai_prompt_version,
        t.labeled_on AS ai_labeled_on
    FROM themes AS t
    JOIN {{ ref('fct_complaints') }} AS f
        ON CAST(f.complaint_id AS STRING) = t.complaint_id
),

sampled AS (
    SELECT product, COUNT(*) AS sampled_stories
    FROM joined
    GROUP BY product
)

SELECT
    j.*,
    p.population_stories / s.sampled_stories AS sample_weight
FROM joined AS j
JOIN population AS p ON p.product = j.product
JOIN sampled AS s ON s.product = j.product