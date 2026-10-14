-- ============================================================
-- GOLD: CUSTOMER VALUE SEGMENTS
-- ============================================================
-- Purpose:
--   Segment customers according to:
--   - monetary value
--   - purchase behavior
--   - engagement
--   - retention risk
--
-- Source:
--   gold.customer_retention
--
-- Grain:
--   One row per customer
-- ============================================================


DROP TABLE IF EXISTS gold.customer_value_segments;


CREATE TABLE gold.customer_value_segments AS

WITH base AS (

    SELECT
        user_id,
        username,

        lifetime_value,
        total_orders,
        average_order_value,
        total_units_purchased,

        customer_age_days,
        days_since_last_order,
        repeat_orders,
        avg_days_between_orders,

        total_events,
        login_events,
        product_views,
        cart_additions,
        checkout_started,
        payment_started,
        purchase_events,

        engagement_level,
        retention_status,

        total_reviews,
        average_rating,

        is_repeat_customer,
        has_retained,
        is_at_risk,
        is_churned

    FROM gold.customer_retention
),


customer_stats AS (

    SELECT
        *,
        
        /*
         * Average lifetime value among customers
         * who have actually purchased.
         */
        AVG(
            NULLIF(lifetime_value, 0)
        ) OVER () AS average_customer_ltv,

        /*
         * Maximum lifetime value among purchasing customers.
         */
        MAX(lifetime_value) OVER () AS maximum_customer_ltv

    FROM base
),


scored AS (

    SELECT
        *,

        -- ====================================================
        -- VALUE SCORE: 0-40
        -- ====================================================

        CASE
            WHEN lifetime_value = 0 THEN 0

            WHEN lifetime_value >= average_customer_ltv
                THEN 40

            ELSE 25
        END AS value_score,


        -- ====================================================
        -- PURCHASE FREQUENCY SCORE: 0-20
        -- ====================================================

        CASE
            WHEN total_orders >= 5 THEN 20
            WHEN total_orders >= 3 THEN 15
            WHEN total_orders >= 2 THEN 10
            WHEN total_orders = 1 THEN 5
            ELSE 0
        END AS purchase_frequency_score,


        -- ====================================================
        -- ENGAGEMENT SCORE: 0-20
        -- ====================================================

        CASE
            WHEN engagement_level = 'HIGH_ENGAGEMENT'
                THEN 20

            WHEN engagement_level = 'MEDIUM_ENGAGEMENT'
                THEN 12

            WHEN engagement_level = 'LOW_ENGAGEMENT'
                THEN 6

            ELSE 0
        END AS engagement_score,


        -- ====================================================
        -- ACTIVITY SCORE: 0-10
        -- ====================================================

        CASE
            WHEN total_events >= 10 THEN 10
            WHEN total_events >= 5 THEN 7
            WHEN total_events >= 3 THEN 5
            WHEN total_events > 0 THEN 2
            ELSE 0
        END AS activity_score,


        -- ====================================================
        -- SATISFACTION SCORE: 0-10
        -- ====================================================

        CASE
            WHEN average_rating >= 4.5 THEN 10
            WHEN average_rating >= 4.0 THEN 8
            WHEN average_rating >= 3.0 THEN 5
            WHEN average_rating > 0 THEN 2
            ELSE 0
        END AS satisfaction_score

    FROM customer_stats
),


classified AS (

    SELECT
        *,

        /*
         * Composite customer value score.
         * Maximum = 100.
         */
        (
            value_score
            + purchase_frequency_score
            + engagement_score
            + activity_score
            + satisfaction_score
        ) AS customer_value_score,


        -- ====================================================
        -- CUSTOMER SEGMENT
        -- ====================================================

        CASE

            WHEN total_orders > 0
                 AND is_at_risk = TRUE
                 AND lifetime_value >= average_customer_ltv
                THEN 'HIGH_VALUE_AT_RISK'


            WHEN total_orders > 0
                 AND lifetime_value >= average_customer_ltv
                THEN 'HIGH_VALUE_ACTIVE'


            WHEN total_orders >= 2
                THEN 'REPEAT_CUSTOMER'


            WHEN total_orders = 1
                THEN 'ONE_TIME_CUSTOMER'


            WHEN total_orders = 0
                 AND total_events > 0
                THEN 'ENGAGED_NON_BUYER'


            WHEN total_orders = 0
                 AND total_events = 0
                THEN 'NEVER_PURCHASED'


            ELSE 'INACTIVE_CUSTOMER'

        END AS customer_segment,


        -- ====================================================
        -- VALUE TIER
        -- ====================================================

        CASE

            WHEN lifetime_value >= average_customer_ltv
                 AND lifetime_value > 0
                THEN 'HIGH_VALUE'

            WHEN lifetime_value > 0
                THEN 'STANDARD_VALUE'

            ELSE 'NO_VALUE'

        END AS value_tier,


        -- ====================================================
        -- PURCHASE BEHAVIOR
        -- ====================================================

        CASE

            WHEN total_orders >= 2
                THEN 'REPEAT_BUYER'

            WHEN total_orders = 1
                THEN 'ONE_TIME_BUYER'

            ELSE 'NON_BUYER'

        END AS purchase_behavior,


        -- ====================================================
        -- CUSTOMER RISK
        -- ====================================================

        CASE

            WHEN is_churned = TRUE
                THEN 'CHURNED'

            WHEN is_at_risk = TRUE
                THEN 'AT_RISK'

            WHEN total_orders > 0
                THEN 'ACTIVE'

            WHEN total_events > 0
                THEN 'ENGAGED'

            ELSE 'INACTIVE'

        END AS customer_risk_status

    FROM scored
)


SELECT

    -- Customer identity
    user_id,
    username,

    -- Segmentation
    customer_segment,
    value_tier,
    purchase_behavior,
    customer_risk_status,

    -- Composite score
    customer_value_score,

    -- Score components
    value_score,
    purchase_frequency_score,
    engagement_score,
    activity_score,
    satisfaction_score,

    -- Monetary metrics
    lifetime_value,
    average_customer_ltv,
    average_order_value,
    total_units_purchased,

    -- Purchase metrics
    total_orders,
    repeat_orders,
    is_repeat_customer,

    -- Customer lifecycle
    customer_age_days,
    days_since_last_order,
    avg_days_between_orders,

    -- Engagement
    total_events,
    login_events,
    product_views,
    cart_additions,
    checkout_started,
    payment_started,
    purchase_events,

    engagement_level,
    retention_status,

    -- Satisfaction
    total_reviews,
    average_rating,

    -- Risk flags
    has_retained,
    is_at_risk,
    is_churned,

    CURRENT_TIMESTAMP AS gold_created_at

FROM classified;


-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_customer_value_segments_user_id
    ON gold.customer_value_segments(user_id);


CREATE INDEX idx_customer_value_segments_segment
    ON gold.customer_value_segments(customer_segment);


CREATE INDEX idx_customer_value_segments_score
    ON gold.customer_value_segments(customer_value_score DESC);


CREATE INDEX idx_customer_value_segments_risk
    ON gold.customer_value_segments(customer_risk_status);


-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE gold.customer_value_segments
IS 'Customer segmentation based on monetary value, purchase behavior, engagement and retention risk.';


COMMENT ON COLUMN gold.customer_value_segments.customer_segment
IS 'Business-oriented customer segment combining purchase behavior, customer value and engagement.';


COMMENT ON COLUMN gold.customer_value_segments.customer_value_score
IS 'Composite customer value score ranging from 0 to 100.';


COMMENT ON COLUMN gold.customer_value_segments.value_score
IS 'Monetary value component of the customer score, maximum 40 points.';


COMMENT ON COLUMN gold.customer_value_segments.purchase_frequency_score
IS 'Purchase frequency component of the customer score, maximum 20 points.';


COMMENT ON COLUMN gold.customer_value_segments.engagement_score
IS 'Engagement component of the customer score, maximum 20 points.';


COMMENT ON COLUMN gold.customer_value_segments.activity_score
IS 'Customer activity component of the customer score, maximum 10 points.';


COMMENT ON COLUMN gold.customer_value_segments.satisfaction_score
IS 'Customer satisfaction component based on reviews, maximum 10 points.';


COMMENT ON COLUMN gold.customer_value_segments.customer_risk_status
IS 'Current customer lifecycle and retention risk classification.';