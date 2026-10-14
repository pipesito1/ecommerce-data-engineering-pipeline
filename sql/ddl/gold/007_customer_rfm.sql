-- ============================================================
-- GOLD: CUSTOMER RFM ANALYSIS
-- Purpose:
--   Segment customers using Recency, Frequency and Monetary
--   value based on gold.customer_retention.
--
-- RFM:
--   Recency   = days since last purchase
--   Frequency = total number of orders
--   Monetary  = customer lifetime value
-- ============================================================

DROP TABLE IF EXISTS gold.customer_rfm;

CREATE TABLE gold.customer_rfm AS

WITH base_customers AS (
    SELECT
        user_id,
        username,

        -- RFM base metrics
        days_since_last_order AS recency_days,
        total_orders AS frequency_orders,
        lifetime_value AS monetary_value,

        -- Existing customer intelligence
        average_order_value,
        total_units_purchased,
        customer_age_days,
        avg_days_between_orders,
        engagement_level,
        retention_status,
        is_repeat_customer,
        is_at_risk,
        is_churned,

        total_events,
        login_events,
        product_views,
        cart_additions,
        checkout_started,
        payment_started,
        purchase_events

    FROM gold.customer_retention
),

rfm_scored AS (
    SELECT
        *,

        /*
         * Recency:
         * Lower number of days is better.
         * Customers with no purchase receive score 0.
         */
        CASE
            WHEN frequency_orders = 0 THEN 0
            ELSE 6 - NTILE(5) OVER (
                ORDER BY recency_days ASC
            )
        END AS recency_score,

        /*
         * Frequency:
         * More orders = higher score.
         */
        CASE
            WHEN frequency_orders = 0 THEN 0
            ELSE NTILE(5) OVER (
                ORDER BY frequency_orders ASC
            )
        END AS frequency_score,

        /*
         * Monetary:
         * Higher lifetime value = higher score.
         */
        CASE
            WHEN monetary_value <= 0 THEN 0
            ELSE NTILE(5) OVER (
                ORDER BY monetary_value ASC
            )
        END AS monetary_score

    FROM base_customers
),

rfm_final AS (
    SELECT
        *,

        (
            recency_score
            + frequency_score
            + monetary_score
        ) AS rfm_score,

        CONCAT(
            recency_score,
            frequency_score,
            monetary_score
        ) AS rfm_code

    FROM rfm_scored
)

SELECT
    user_id,
    username,

    -- RFM metrics
    recency_days,
    frequency_orders,
    monetary_value,

    recency_score,
    frequency_score,
    monetary_score,

    rfm_score,
    rfm_code,

    -- Business segmentation
    CASE

        WHEN frequency_orders = 0
             AND total_events > 0
            THEN 'ENGAGED_NON_BUYER'

        WHEN frequency_orders = 0
            THEN 'NEVER_PURCHASED'

        WHEN rfm_score >= 13
            THEN 'CHAMPIONS'

        WHEN rfm_score >= 11
             AND recency_score >= 4
            THEN 'LOYAL_CUSTOMERS'

        WHEN rfm_score >= 9
             AND recency_score >= 4
            THEN 'POTENTIAL_LOYALISTS'

        WHEN recency_score >= 4
             AND frequency_score <= 2
            THEN 'NEW_CUSTOMERS'

        WHEN recency_score <= 2
             AND frequency_score >= 4
            THEN 'AT_RISK_HIGH_VALUE'

        WHEN recency_score <= 2
             AND monetary_score >= 4
            THEN 'CANNOT_LOSE'

        WHEN recency_score <= 2
            THEN 'HIBERNATING'

        WHEN monetary_score >= 4
            THEN 'HIGH_VALUE'

        ELSE 'OTHER_CUSTOMERS'

    END AS rfm_segment,

    -- Customer priority
    CASE

        WHEN frequency_orders = 0
             AND total_events > 0
            THEN 'MEDIUM'

        WHEN rfm_score >= 13
            THEN 'CRITICAL'

        WHEN rfm_score >= 11
            THEN 'HIGH'

        WHEN rfm_score >= 8
            THEN 'MEDIUM'

        WHEN frequency_orders > 0
            THEN 'LOW'

        ELSE 'NONE'

    END AS customer_priority,

    -- Existing customer intelligence
    average_order_value,
    total_units_purchased,
    customer_age_days,
    avg_days_between_orders,

    engagement_level,
    retention_status,
    is_repeat_customer,
    is_at_risk,
    is_churned,

    total_events,
    login_events,
    product_views,
    cart_additions,
    checkout_started,
    payment_started,
    purchase_events,

    CURRENT_TIMESTAMP AS gold_created_at

FROM rfm_final;


-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_customer_rfm_user_id
    ON gold.customer_rfm(user_id);

CREATE INDEX idx_customer_rfm_segment
    ON gold.customer_rfm(rfm_segment);

CREATE INDEX idx_customer_rfm_score
    ON gold.customer_rfm(rfm_score);

CREATE INDEX idx_customer_rfm_priority
    ON gold.customer_rfm(customer_priority);


-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE gold.customer_rfm
IS 'Customer RFM analysis using recency, frequency and monetary value.';

COMMENT ON COLUMN gold.customer_rfm.recency_days
IS 'Number of days since the customer last placed an order.';

COMMENT ON COLUMN gold.customer_rfm.frequency_orders
IS 'Total number of orders placed by the customer.';

COMMENT ON COLUMN gold.customer_rfm.monetary_value
IS 'Customer lifetime value based on total paid order value.';

COMMENT ON COLUMN gold.customer_rfm.recency_score
IS 'RFM recency score from 1 to 5, where 5 represents more recent customers.';

COMMENT ON COLUMN gold.customer_rfm.frequency_score
IS 'RFM frequency score from 1 to 5, where 5 represents more frequent customers.';

COMMENT ON COLUMN gold.customer_rfm.monetary_score
IS 'RFM monetary score from 1 to 5, where 5 represents higher customer value.';

COMMENT ON COLUMN gold.customer_rfm.rfm_score
IS 'Combined RFM score from 3 to 15.';

COMMENT ON COLUMN gold.customer_rfm.rfm_code
IS 'Three-digit RFM code representing recency, frequency and monetary scores.';

COMMENT ON COLUMN gold.customer_rfm.rfm_segment
IS 'Business customer segment derived from RFM scores.';

COMMENT ON COLUMN gold.customer_rfm.customer_priority
IS 'Business priority for customer engagement and retention actions.';