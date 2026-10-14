-- ============================================================
-- GOLD: CUSTOMER PURCHASE BEHAVIOR
-- ============================================================
-- Grain: 1 row per customer
--
-- Purpose:
-- ============================================================
-- GOLD: CUSTOMER PURCHASE BEHAVIOR
-- ============================================================
-- Grain: 1 row per customer
--
-- Purpose:
-- Analyze customer purchasing behavior, purchase frequency,
-- purchase recency, customer value and buying profile.
--
-- Sources:
--   gold.customer_360
--   gold.customer_retention
--   gold.customer_rfm
--   gold.customer_value_segments
--   gold.customer_churn_risk
-- ============================================================


DROP TABLE IF EXISTS gold.customer_purchase_behavior;


CREATE TABLE gold.customer_purchase_behavior AS

WITH ltv_thresholds AS (

    SELECT
        PERCENTILE_CONT(0.50)
            WITHIN GROUP (ORDER BY lifetime_value)::numeric
            AS median_ltv,

        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY lifetime_value)::numeric
            AS p75_ltv

    FROM gold.customer_retention

    WHERE lifetime_value > 0
),

customer_behavior AS (

    SELECT

        c.user_id,
        c.username,
        c.country,
        c.currency,

        -- ====================================================
        -- Customer lifecycle
        -- ====================================================

        c.customer_created_at,

        r.first_order_date,
        r.last_order_date,

        r.customer_age_days,
        r.days_since_last_order,


        -- ====================================================
        -- Purchase volume
        -- ====================================================

        COALESCE(r.total_orders, 0) AS total_orders,

        COALESCE(r.repeat_orders, 0) AS repeat_orders,

        COALESCE(r.total_units_purchased, 0)
            AS total_units_purchased,

        COALESCE(r.is_repeat_customer, FALSE)
            AS is_repeat_customer,


        -- ====================================================
        -- Purchase value
        -- ====================================================

        COALESCE(r.lifetime_value, 0)
            AS lifetime_value,

        COALESCE(r.average_order_value, 0)
            AS average_order_value,


        -- ====================================================
        -- Purchase frequency
        -- ====================================================

        COALESCE(r.avg_days_between_orders, 0)
            AS avg_days_between_orders,


        CASE

            WHEN COALESCE(r.total_orders, 0) = 0
                THEN 0::numeric

            WHEN COALESCE(r.customer_age_days, 0) <= 0
                THEN r.total_orders::numeric

            ELSE ROUND(
                r.total_orders::numeric /
                GREATEST(
                    r.customer_age_days::numeric / 30.0,
                    1
                ),
                2
            )

        END AS orders_per_30_days,


        CASE

            WHEN COALESCE(r.total_orders, 0) = 0
                THEN 0::numeric

            ELSE ROUND(
                r.total_units_purchased::numeric /
                NULLIF(r.total_orders, 0),
                2
            )

        END AS units_per_order,


        -- ====================================================
        -- Purchase behavior
        -- ====================================================

        CASE

            WHEN COALESCE(r.total_orders, 0) = 0
                THEN 'NON_BUYER'

            WHEN r.total_orders = 1
                THEN 'ONE_TIME_BUYER'

            WHEN r.total_orders BETWEEN 2 AND 3
                THEN 'REPEAT_BUYER'

            WHEN r.total_orders >= 4
                THEN 'FREQUENT_BUYER'

            ELSE 'UNKNOWN'

        END AS purchase_behavior,


        CASE

            WHEN COALESCE(r.total_orders, 0) = 0
                THEN 'NO_PURCHASE'

            WHEN r.total_orders = 1
                THEN 'LOW_FREQUENCY'

            WHEN r.avg_days_between_orders IS NULL
                THEN 'LOW_FREQUENCY'

            WHEN r.avg_days_between_orders <= 30
                THEN 'HIGH_FREQUENCY'

            WHEN r.avg_days_between_orders <= 90
                THEN 'MEDIUM_FREQUENCY'

            ELSE 'LOW_FREQUENCY'

        END AS purchase_frequency_segment,


        -- ====================================================
        -- Customer value
        -- ====================================================

        CASE

            WHEN COALESCE(r.lifetime_value, 0) = 0
                THEN 'NO_VALUE'

            WHEN r.lifetime_value >= t.p75_ltv
                THEN 'HIGH_VALUE'

            WHEN r.lifetime_value >= t.median_ltv
                THEN 'MEDIUM_VALUE'

            ELSE 'STANDARD_VALUE'

        END AS purchase_value_segment,


        -- ====================================================
        -- Purchase recency
        -- ====================================================

        CASE

            WHEN COALESCE(r.total_orders, 0) = 0
                THEN 'NO_PURCHASE'

            WHEN r.days_since_last_order <= 30
                THEN 'RECENT'

            WHEN r.days_since_last_order <= 90
                THEN 'AGING'

            WHEN r.days_since_last_order <= 180
                THEN 'AT_RISK'

            ELSE 'DORMANT'

        END AS purchase_recency_segment,


        -- ====================================================
        -- Combined purchase profile
        -- ====================================================

        CASE

            WHEN COALESCE(r.total_orders, 0) = 0
                 AND COALESCE(c.total_events, 0) > 0
                THEN 'ENGAGED_NON_BUYER'

            WHEN COALESCE(r.total_orders, 0) = 0
                 AND COALESCE(c.total_events, 0) = 0
                THEN 'INACTIVE_NON_BUYER'

            WHEN r.total_orders = 1
                THEN 'ONE_TIME_CUSTOMER'

            WHEN r.total_orders >= 2
                 AND r.days_since_last_order <= 30
                THEN 'ACTIVE_REPEAT_CUSTOMER'

            WHEN r.total_orders >= 2
                 AND r.days_since_last_order <= 90
                THEN 'AGING_REPEAT_CUSTOMER'

            WHEN r.total_orders >= 2
                THEN 'DORMANT_REPEAT_CUSTOMER'

            ELSE 'UNCLASSIFIED'

        END AS customer_purchase_profile,


        -- ====================================================
        -- Existing customer dimensions
        -- ====================================================

        c.engagement_level,

        r.retention_status,

        rf.rfm_segment,

        rf.customer_priority,

        vs.customer_segment,

        vs.value_tier,

        cr.churn_risk_level,

        cr.churn_risk_segment,


        -- ====================================================
        -- Engagement context
        -- ====================================================

        COALESCE(c.total_events, 0)
            AS total_events,

        COALESCE(c.product_views, 0)
            AS product_views,

        COALESCE(c.cart_additions, 0)
            AS cart_additions,

        COALESCE(c.checkout_started, 0)
            AS checkout_started,

        COALESCE(c.payment_started, 0)
            AS payment_started,

        COALESCE(c.purchase_events, 0)
            AS purchase_events,


        -- ====================================================
        -- Conversion metrics
        -- ====================================================

        COALESCE(c.session_to_purchase_rate, 0)
            AS session_to_purchase_rate,

        COALESCE(c.view_to_cart_rate, 0)
            AS view_to_cart_rate,

        COALESCE(c.checkout_to_purchase_rate, 0)
            AS checkout_to_purchase_rate,


        -- ====================================================
        -- Customer flags
        -- ====================================================

        COALESCE(c.has_purchased, FALSE)
            AS has_purchased,

        COALESCE(r.has_retained, FALSE)
            AS has_retained,

        COALESCE(r.is_at_risk, FALSE)
            AS is_at_risk,

        COALESCE(r.is_churned, FALSE)
            AS is_churned


    FROM gold.customer_360 c

    LEFT JOIN gold.customer_retention r
        ON c.user_id = r.user_id

    LEFT JOIN gold.customer_rfm rf
        ON c.user_id = rf.user_id

    LEFT JOIN gold.customer_value_segments vs
        ON c.user_id = vs.user_id

    LEFT JOIN gold.customer_churn_risk cr
        ON c.user_id = cr.user_id

    CROSS JOIN ltv_thresholds t
)


SELECT

    customer_behavior.*,

    CURRENT_TIMESTAMP AS gold_created_at

FROM customer_behavior;


-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_customer_purchase_behavior_user_id
    ON gold.customer_purchase_behavior(user_id);

CREATE INDEX idx_customer_purchase_behavior_purchase_behavior
    ON gold.customer_purchase_behavior(purchase_behavior);

CREATE INDEX idx_customer_purchase_behavior_frequency
    ON gold.customer_purchase_behavior(purchase_frequency_segment);

CREATE INDEX idx_customer_purchase_behavior_value
    ON gold.customer_purchase_behavior(purchase_value_segment);

CREATE INDEX idx_customer_purchase_behavior_profile
    ON gold.customer_purchase_behavior(customer_purchase_profile);

CREATE INDEX idx_customer_purchase_behavior_ltv
    ON gold.customer_purchase_behavior(lifetime_value);


-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE gold.customer_purchase_behavior IS
    'Customer-level purchasing behavior analysis. Grain: one row per customer.';


COMMENT ON COLUMN gold.customer_purchase_behavior.purchase_behavior IS
    'Classifies customers as non-buyers, one-time buyers, repeat buyers or frequent buyers.';


COMMENT ON COLUMN gold.customer_purchase_behavior.purchase_frequency_segment IS
    'Customer purchase frequency classification based on order cadence.';


COMMENT ON COLUMN gold.customer_purchase_behavior.purchase_value_segment IS
    'Customer value classification based on lifetime value distribution.';


COMMENT ON COLUMN gold.customer_purchase_behavior.purchase_recency_segment IS
    'Purchase recency classification based on days since last order.';


COMMENT ON COLUMN gold.customer_purchase_behavior.customer_purchase_profile IS
    'Combined customer purchasing profile based on purchase activity, recency and engagement.';


COMMENT ON COLUMN gold.customer_purchase_behavior.orders_per_30_days IS
    'Estimated number of customer orders per 30-day period.';


COMMENT ON COLUMN gold.customer_purchase_behavior.units_per_order IS
    'Average number of units purchased per order.';