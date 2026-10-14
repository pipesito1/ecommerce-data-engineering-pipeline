DROP TABLE IF EXISTS gold.customer_engagement_analysis;

CREATE TABLE gold.customer_engagement_analysis AS
WITH base AS (
    SELECT
        user_id,
        username,
        country,
        currency,
        customer_created_at,

        total_events,
        total_sessions,
        login_events,
        product_views,
        cart_additions,
        checkout_started,
        payment_started,
        purchase_events,
        unique_products_interacted,

        session_to_purchase_rate,
        view_to_cart_rate,
        checkout_to_purchase_rate,

        total_orders,
        lifetime_value,
        average_order_value,
        has_purchased,
        has_abandoned_cart,
        has_reviewed,

        customer_segment,
        engagement_level AS source_engagement_level,
        days_since_last_order,
        last_event_at,

        CASE
            WHEN total_events = 0 THEN 0
            ELSE ROUND(
                (
                    LEAST(total_events, 20) * 2
                    + LEAST(total_sessions, 10) * 2
                    + LEAST(product_views, 10) * 2
                    + LEAST(cart_additions, 5) * 3
                    + LEAST(checkout_started, 5) * 4
                    + LEAST(payment_started, 5) * 4
                    + LEAST(purchase_events, 5) * 5
                )::numeric,
                2
            )
        END AS raw_engagement_score

    FROM gold.customer_360
),

scored AS (
    SELECT
        *,
        LEAST(raw_engagement_score, 100) AS engagement_score,

        CASE
            WHEN has_purchased = TRUE
                 AND total_events = 0
                THEN 'PURCHASE_WITHOUT_TRACKED_ENGAGEMENT'

            WHEN total_events = 0
                THEN 'NO_ENGAGEMENT'

            WHEN raw_engagement_score >= 70
                THEN 'HIGH_ENGAGEMENT'

            WHEN raw_engagement_score >= 40
                THEN 'MEDIUM_ENGAGEMENT'

            ELSE 'LOW_ENGAGEMENT'
        END AS calculated_engagement_level

    FROM base
),

classified AS (
    SELECT
        *,

        CASE
            WHEN has_purchased = TRUE
                 AND total_events = 0
                THEN 'PURCHASER_WITHOUT_TRACKED_ENGAGEMENT'

            WHEN total_events = 0
                THEN 'INACTIVE_NON_CUSTOMER'

            WHEN has_purchased = TRUE
                 AND raw_engagement_score >= 70
                THEN 'HIGHLY_ENGAGED_CUSTOMER'

            WHEN has_purchased = TRUE
                 AND raw_engagement_score >= 40
                THEN 'ENGAGED_CUSTOMER'

            WHEN has_purchased = TRUE
                THEN 'LOW_ENGAGEMENT_CUSTOMER'

            WHEN raw_engagement_score >= 70
                THEN 'HIGH_INTENT_NON_BUYER'

            WHEN raw_engagement_score >= 40
                THEN 'ENGAGED_NON_BUYER'

            ELSE 'LOW_ENGAGEMENT_NON_BUYER'
        END AS engagement_segment,

        CASE
            WHEN has_purchased = TRUE
                 AND total_events = 0
                THEN 'HIGH'

            WHEN has_purchased = TRUE
                 AND raw_engagement_score >= 70
                THEN 'HIGH'

            WHEN has_purchased = TRUE
                 AND raw_engagement_score >= 40
                THEN 'MEDIUM'

            WHEN has_purchased = TRUE
                THEN 'MEDIUM'

            WHEN raw_engagement_score >= 70
                THEN 'HIGH'

            WHEN raw_engagement_score >= 40
                THEN 'MEDIUM'

            ELSE 'LOW'
        END AS engagement_business_priority

    FROM scored
)

SELECT
    user_id,
    username,
    country,
    currency,
    customer_created_at,

    total_events,
    total_sessions,
    login_events,
    product_views,
    cart_additions,
    checkout_started,
    payment_started,
    purchase_events,
    unique_products_interacted,

    session_to_purchase_rate,
    view_to_cart_rate,
    checkout_to_purchase_rate,

    total_orders,
    lifetime_value,
    average_order_value,
    has_purchased,
    has_abandoned_cart,
    has_reviewed,

    customer_segment,
    source_engagement_level,
    calculated_engagement_level,

    engagement_score,
    engagement_segment,
    engagement_business_priority,

    days_since_last_order,
    last_event_at,

    CASE
        WHEN has_purchased = TRUE
             AND total_events = 0
            THEN 'TRACKING_REVIEW'

        WHEN total_events = 0
            THEN 'REACTIVATION_CAMPAIGN'

        WHEN has_purchased = TRUE
             AND raw_engagement_score >= 70
            THEN 'RETENTION_AND_UPSELL'

        WHEN has_purchased = TRUE
             AND raw_engagement_score >= 40
            THEN 'SECOND_PURCHASE_CAMPAIGN'

        WHEN has_purchased = TRUE
            THEN 'REENGAGEMENT_CAMPAIGN'

        WHEN raw_engagement_score >= 70
            THEN 'CONVERSION_CAMPAIGN'

        WHEN raw_engagement_score >= 40
            THEN 'NURTURE_CAMPAIGN'

        ELSE 'LOW_COST_REMARKETING'
    END AS recommended_action,

    NOW() AS gold_created_at

FROM classified;

CREATE INDEX idx_customer_engagement_user_id
    ON gold.customer_engagement_analysis(user_id);

CREATE INDEX idx_customer_engagement_score
    ON gold.customer_engagement_analysis(engagement_score);

CREATE INDEX idx_customer_engagement_segment
    ON gold.customer_engagement_analysis(engagement_segment);

CREATE INDEX idx_customer_engagement_priority
    ON gold.customer_engagement_analysis(engagement_business_priority);

CREATE INDEX idx_customer_engagement_purchased
    ON gold.customer_engagement_analysis(has_purchased);

CREATE INDEX idx_customer_engagement_action
    ON gold.customer_engagement_analysis(recommended_action);

COMMENT ON TABLE gold.customer_engagement_analysis IS
'Customer engagement scoring and behavioral segmentation for ecommerce analytics.';

COMMENT ON COLUMN gold.customer_engagement_analysis.engagement_score IS
'Normalized customer engagement score from 0 to 100 based on behavioral activity.';

COMMENT ON COLUMN gold.customer_engagement_analysis.engagement_segment IS
'Behavioral segmentation combining engagement intensity and purchase status.';

COMMENT ON COLUMN gold.customer_engagement_analysis.engagement_business_priority IS
'Business priority assigned according to engagement and purchase behavior.';

COMMENT ON COLUMN gold.customer_engagement_analysis.recommended_action IS
'Recommended business action based on customer engagement and purchase behavior.';