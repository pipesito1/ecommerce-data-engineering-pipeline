-- ============================================================
-- SILVER LAYER
-- 005_reviews.sql
-- Cleaned and enriched product reviews
-- ============================================================

DROP TABLE IF EXISTS silver.reviews;

CREATE TABLE silver.reviews AS
SELECT
    -- Review identifiers
    r.review_id,
    r.user_id,
    r.product_id,

    -- Customer information
    u.username,
    u.first_name,
    u.last_name,
    u.country AS customer_country,

    -- Product information
    p.product_name,
    p.sku,
    p.sale_price,
    p.currency,

    -- Review information
    r.rating,
    TRIM(r.review_title) AS review_title,
    TRIM(r.review_text) AS review_text,

    -- Review flags
    r.is_verified_purchase,
    r.is_approved,

    -- Rating classification
    CASE
        WHEN r.rating >= 5 THEN 'EXCELLENT'
        WHEN r.rating = 4 THEN 'GOOD'
        WHEN r.rating = 3 THEN 'NEUTRAL'
        WHEN r.rating = 2 THEN 'POOR'
        WHEN r.rating <= 1 THEN 'VERY_POOR'
        ELSE 'UNKNOWN'
    END AS rating_category,

    -- Positive / negative review flags
    CASE
        WHEN r.rating >= 4 THEN TRUE
        ELSE FALSE
    END AS is_positive_review,

    CASE
        WHEN r.rating <= 2 THEN TRUE
        ELSE FALSE
    END AS is_negative_review,

    -- Review text analytics
    CASE
        WHEN r.review_text IS NULL
             OR TRIM(r.review_text) = ''
            THEN 0
        ELSE LENGTH(TRIM(r.review_text))
    END AS review_text_length,

    CASE
        WHEN r.review_text IS NULL
             OR TRIM(r.review_text) = ''
            THEN 0
        ELSE ARRAY_LENGTH(
            REGEXP_SPLIT_TO_ARRAY(
                TRIM(r.review_text),
                '\s+'
            ),
            1
        )
    END AS review_word_count,

    -- Review date attributes
    r.created_at AS review_created_at,
    r.updated_at AS review_updated_at,
    r.created_at::date AS review_date,

    EXTRACT(
        MONTH FROM r.created_at
    )::integer AS review_month,

    EXTRACT(
        YEAR FROM r.created_at
    )::integer AS review_year,

    -- Metadata
    r.deleted_at,
    r.ingestion_timestamp,
    r.source_system,
    r.batch_id,
    r.record_hash

FROM bronze.reviews r

LEFT JOIN bronze.users u
    ON r.user_id = u.user_id

LEFT JOIN bronze.products p
    ON r.product_id = p.product_id

WHERE r.deleted_at IS NULL;


-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_silver_reviews_user
    ON silver.reviews(user_id);

CREATE INDEX idx_silver_reviews_product
    ON silver.reviews(product_id);

CREATE INDEX idx_silver_reviews_rating
    ON silver.reviews(rating);

CREATE INDEX idx_silver_reviews_date
    ON silver.reviews(review_date);

CREATE INDEX idx_silver_reviews_verified
    ON silver.reviews(is_verified_purchase);


-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE silver.reviews IS
'Cleaned and enriched product reviews joined with customer and product information for customer feedback and product quality analysis.';

COMMENT ON COLUMN silver.reviews.rating_category IS
'Normalized rating classification based on the review rating.';

COMMENT ON COLUMN silver.reviews.is_positive_review IS
'Indicates whether the review has a rating of 4 or 5.';

COMMENT ON COLUMN silver.reviews.is_negative_review IS
'Indicates whether the review has a rating of 1 or 2.';

COMMENT ON COLUMN silver.reviews.review_word_count IS
'Number of words contained in the review text.';