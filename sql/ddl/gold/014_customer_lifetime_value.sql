DROP TABLE IF EXISTS gold.customer_lifetime_value;

CREATE TABLE gold.customer_lifetime_value AS

WITH customer_base AS (

    SELECT
        c.user_id,
        c.username,
        c.country,
        c.currency,
        c.customer_created_at,

        c.total_orders,
        COALESCE(c.lifetime_value, 0)::numeric AS lifetime_value,
        COALESCE(c.average_order_value, 0)::numeric AS average_order_value,

        c.total_events,
        c.total_sessions,
        c.purchase_events,
        c.days_since_last_order,
        c.has_purchased,

        c.customer_segment

    FROM gold.customer_360 c
),

metrics AS (

    SELECT
        *,

        CASE
            WHEN total_orders = 0 THEN 0
            WHEN lifetime_value >= 2000000 THEN 100
            WHEN lifetime_value >= 1000000 THEN 85
            WHEN lifetime_value >= 500000 THEN 70
            ELSE 40
        END AS value_score,

        CASE
            WHEN total_orders = 0 THEN 0
            WHEN total_orders >= 5 THEN 100
            WHEN total_orders >= 3 THEN 85
            WHEN total_orders >= 2 THEN 70
            ELSE 50
        END AS frequency_score

    FROM customer_base
),

scored AS (

    SELECT
        *,

        CASE
            WHEN total_orders = 0 THEN 0

            ELSE ROUND(
                (value_score * 0.70)
                + (frequency_score * 0.30),
                0
            )
        END AS ltv_score

    FROM metrics
),

classified AS (

    SELECT
        *,

        CASE
            WHEN total_orders = 0
                THEN 'NO_CUSTOMER'

            WHEN lifetime_value >= 2000000
                THEN 'VERY_HIGH_VALUE'

            WHEN lifetime_value >= 1000000
                THEN 'HIGH_VALUE'

            WHEN lifetime_value >= 500000
                THEN 'STANDARD_VALUE'

            ELSE 'LOW_VALUE'

        END AS historical_value_segment,

        CASE
            WHEN total_orders = 0
                THEN 'NO_PURCHASE'

            WHEN total_orders >= 5
                THEN 'HIGH_FREQUENCY'

            WHEN total_orders >= 3
                THEN 'MEDIUM_FREQUENCY'

            WHEN total_orders >= 2
                THEN 'REPEAT_BUYER'

            ELSE 'ONE_TIME_BUYER'

        END AS purchase_frequency_segment

    FROM scored
),

final AS (

    SELECT
        *,

        CASE
            WHEN total_orders = 0
                THEN 'NO_LTV'

            WHEN ltv_score >= 85
                THEN 'HIGH_LTV'

            WHEN ltv_score >= 60
                THEN 'MEDIUM_LTV'

            ELSE 'LOW_LTV'

        END AS ltv_segment,

        CASE
            WHEN total_orders = 0
                THEN 'NONE'

            WHEN ltv_score >= 85
                THEN 'CRITICAL'

            WHEN ltv_score >= 60
                THEN 'HIGH'

            WHEN ltv_score >= 50
                THEN 'MEDIUM'

            ELSE 'LOW'

        END AS business_priority,

        CASE
            WHEN total_orders = 0
                THEN 'ACQUISITION_CAMPAIGN'

            WHEN lifetime_value >= 2000000
                 AND total_orders = 1
                THEN 'HIGH_VALUE_RETENTION'

            WHEN total_orders = 1
                THEN 'SECOND_PURCHASE_CAMPAIGN'

            WHEN total_orders >= 2
                 AND lifetime_value >= 1000000
                THEN 'LOYALTY_AND_UPSELL'

            WHEN total_orders >= 2
                THEN 'RETENTION_CAMPAIGN'

            ELSE 'CUSTOMER_DEVELOPMENT'

        END AS recommended_action

    FROM classified
)

SELECT
    user_id,
    username,
    country,
    currency,
    customer_created_at,

    total_orders,
    lifetime_value,
    average_order_value,

    total_events,
    total_sessions,
    purchase_events,
    days_since_last_order,
    has_purchased,

    customer_segment,

    value_score,
    frequency_score,
    ltv_score,

    historical_value_segment,
    purchase_frequency_segment,
    ltv_segment,

    business_priority,
    recommended_action,

    NOW() AS gold_created_at

FROM final;


CREATE INDEX idx_customer_ltv_user_id
    ON gold.customer_lifetime_value(user_id);

CREATE INDEX idx_customer_ltv_score
    ON gold.customer_lifetime_value(ltv_score);

CREATE INDEX idx_customer_ltv_segment
    ON gold.customer_lifetime_value(ltv_segment);

CREATE INDEX idx_customer_ltv_value
    ON gold.customer_lifetime_value(lifetime_value);

CREATE INDEX idx_customer_ltv_priority
    ON gold.customer_lifetime_value(business_priority);


COMMENT ON TABLE gold.customer_lifetime_value IS
'Customer historical lifetime value and commercial value segmentation.';

COMMENT ON COLUMN gold.customer_lifetime_value.ltv_score IS
'Commercial value score combining historical customer value and purchase frequency.';

COMMENT ON COLUMN gold.customer_lifetime_value.historical_value_segment IS
'Customer classification based on cumulative historical revenue.';

COMMENT ON COLUMN gold.customer_lifetime_value.recommended_action IS
'Recommended commercial action based on customer value and purchase behavior.';