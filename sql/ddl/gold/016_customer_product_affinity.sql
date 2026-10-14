DROP TABLE IF EXISTS gold.customer_product_affinity;

CREATE TABLE gold.customer_product_affinity AS

WITH customer_product_events AS (

    SELECT
        e.user_id,
        u.username,
        e.product_id,

        COUNT(*) AS total_product_events,

        COUNT(*) FILTER (
            WHERE e.is_product_view = TRUE
        ) AS product_views,

        COUNT(*) FILTER (
            WHERE e.is_cart_add = TRUE
        ) AS cart_additions,

        COUNT(*) FILTER (
            WHERE e.is_checkout_started = TRUE
        ) AS checkout_started,

        COUNT(*) FILTER (
            WHERE e.is_payment_started = TRUE
        ) AS payment_started,

        COUNT(*) FILTER (
            WHERE e.is_purchase = TRUE
               OR e.event_type = 'PURCHASE'
        ) AS purchase_events,

        MIN(e.event_timestamp) AS first_interaction_at,
        MAX(e.event_timestamp) AS last_interaction_at,

        COUNT(DISTINCT e.session_id) AS total_sessions

    FROM silver.events e

    INNER JOIN silver.users u
        ON e.user_id = u.user_id

    WHERE e.product_id IS NOT NULL

    GROUP BY
        e.user_id,
        u.username,
        e.product_id
),

customer_totals AS (

    SELECT
        user_id,

        SUM(purchase_events) AS customer_purchase_events,

        SUM(total_product_events) AS customer_total_product_events

    FROM customer_product_events

    GROUP BY user_id
),

enriched AS (

    SELECT
        cpe.*,

        p.sku,
        p.product_name,
        p.category_id,
        p.category_name,
        p.brand_id,
        p.brand_name,
        p.supplier_id,
        p.supplier_name,
        p.currency,
        p.cost_price,
        p.sale_price,
        p.stock_quantity,
        p.low_stock_threshold,
        p.backorder_allowed,
        p.is_active,
        p.is_featured,

        ct.customer_purchase_events,
        ct.customer_total_product_events,

        /*
         * Estimated value based on current product sale price.
         * This is NOT historical transaction revenue.
         */
        ROUND(
            cpe.purchase_events * COALESCE(p.sale_price, 0),
            2
        ) AS estimated_purchase_value

    FROM customer_product_events cpe

    INNER JOIN silver.products p
        ON cpe.product_id = p.product_id

    INNER JOIN customer_totals ct
        ON cpe.user_id = ct.user_id
),

ranked AS (

    SELECT
        e.*,

        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY
                purchase_events DESC,
                checkout_started DESC,
                cart_additions DESC,
                product_views DESC,
                estimated_purchase_value DESC,
                last_interaction_at DESC,
                product_id
        ) AS product_preference_rank,

        SUM(estimated_purchase_value) OVER (
            PARTITION BY user_id
        ) AS customer_estimated_purchase_value

    FROM enriched e
),

scored AS (

    SELECT
        r.*,

        /*
         * Behavioral affinity score:
         *
         * Product view       = 5 points
         * Cart addition      = 10 points
         * Checkout started   = 15 points
         * Payment started    = 20 points
         * Purchase           = 50 points
         *
         * Capped at 100.
         */
        LEAST(
            100,
            (
                product_views * 5
                + cart_additions * 10
                + checkout_started * 15
                + payment_started * 20
                + purchase_events * 50
            )
        )::numeric AS product_affinity_score

    FROM ranked r
)

SELECT
    user_id,
    username,

    product_id,
    sku,
    product_name,

    category_id,
    category_name,

    brand_id,
    brand_name,

    supplier_id,
    supplier_name,

    currency,

    cost_price,
    sale_price,

    total_product_events,
    total_sessions,

    product_views,
    cart_additions,
    checkout_started,
    payment_started,
    purchase_events,

    estimated_purchase_value,

    first_interaction_at,
    last_interaction_at,

    CURRENT_DATE
        - last_interaction_at::date
        AS days_since_last_interaction,

    product_preference_rank,

    ROUND(
        100.0 * estimated_purchase_value
        / NULLIF(customer_estimated_purchase_value, 0),
        2
    ) AS value_affinity_percentage,

    ROUND(
        100.0 * purchase_events
        / NULLIF(customer_purchase_events, 0),
        2
    ) AS purchase_affinity_percentage,

    ROUND(product_affinity_score, 2)
        AS product_affinity_score,

    CASE
        WHEN purchase_events > 0
             AND product_affinity_score >= 80
            THEN 'PURCHASER_HIGH_AFFINITY'

        WHEN purchase_events > 0
            THEN 'PURCHASER_AFFINITY'

        WHEN payment_started > 0
            THEN 'PAYMENT_INTENT'

        WHEN checkout_started > 0
            THEN 'CHECKOUT_INTENT'

        WHEN cart_additions > 0
            THEN 'CART_INTENT'

        WHEN product_views > 0
            THEN 'VIEW_ONLY'

        ELSE 'LOW_AFFINITY'
    END AS product_affinity_segment,

    CASE
        WHEN purchase_events > 0
             AND product_affinity_score >= 80
            THEN 'CRITICAL'

        WHEN purchase_events > 0
            THEN 'HIGH'

        WHEN payment_started > 0
             OR checkout_started > 0
            THEN 'HIGH'

        WHEN cart_additions > 0
            THEN 'MEDIUM'

        WHEN product_views > 0
            THEN 'LOW'

        ELSE 'NONE'
    END AS business_priority,

    CASE
        WHEN purchase_events > 0
             AND product_affinity_score >= 80
            THEN 'LOYALTY_CROSS_SELL'

        WHEN purchase_events > 0
            THEN 'REPEAT_PURCHASE_CAMPAIGN'

        WHEN payment_started > 0
            THEN 'RECOVER_PAYMENT_INTENT'

        WHEN checkout_started > 0
            THEN 'RECOVER_CHECKOUT_ABANDONMENT'

        WHEN cart_additions > 0
            THEN 'CART_ABANDONMENT_CAMPAIGN'

        WHEN product_views > 0
            THEN 'PRODUCT_REMARKETING'

        ELSE 'NO_ACTION'
    END AS recommended_action,

    CASE
        WHEN purchase_events > 0
            THEN 'PURCHASE_CONFIRMED'

        WHEN payment_started > 0
            THEN 'PAYMENT_INTENT'

        WHEN checkout_started > 0
            THEN 'CHECKOUT_INTENT'

        WHEN cart_additions > 0
            THEN 'CART_INTENT'

        WHEN product_views > 0
            THEN 'PRODUCT_INTEREST'

        ELSE 'NO_INTERACTION'
    END AS customer_product_status,

    CURRENT_TIMESTAMP AS gold_created_at

FROM scored;

CREATE INDEX idx_customer_product_affinity_user
    ON gold.customer_product_affinity (user_id);

CREATE INDEX idx_customer_product_affinity_product
    ON gold.customer_product_affinity (product_id);

CREATE INDEX idx_customer_product_affinity_category
    ON gold.customer_product_affinity (category_id);

CREATE INDEX idx_customer_product_affinity_segment
    ON gold.customer_product_affinity (product_affinity_segment);

CREATE INDEX idx_customer_product_affinity_priority
    ON gold.customer_product_affinity (business_priority);


COMMENT ON TABLE gold.customer_product_affinity
    IS 'Behavioral customer-product affinity analysis based on product interactions and purchase events.';

COMMENT ON COLUMN gold.customer_product_affinity.product_affinity_score
    IS 'Weighted behavioral affinity score based on product views, cart additions, checkout, payment and purchase events.';

COMMENT ON COLUMN gold.customer_product_affinity.estimated_purchase_value
    IS 'Estimated purchase value using current product sale price multiplied by purchase events; not historical transaction revenue.';

COMMENT ON COLUMN gold.customer_product_affinity.value_affinity_percentage
    IS 'Percentage of estimated customer purchase value attributed to this product.';

COMMENT ON COLUMN gold.customer_product_affinity.purchase_affinity_percentage
    IS 'Percentage of customer purchase events associated with this product.';

COMMENT ON COLUMN gold.customer_product_affinity.product_preference_rank
    IS 'Ranking of products within each customer based on purchase and behavioral affinity.';

COMMENT ON COLUMN gold.customer_product_affinity.recommended_action
    IS 'Recommended commercial action based on the strongest customer-product interaction stage.';