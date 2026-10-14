-- ============================================================
-- GOLD LAYER
-- 001_customer_360.sql
-- Customer 360 - Customer-level analytical table
-- ============================================================

DROP TABLE IF EXISTS gold.customer_360;

CREATE TABLE gold.customer_360 AS

WITH customer_base AS (

    SELECT
        u.user_id,
        u.username,
        u.email,
        u.last_name,
        u.country,
        u.currency,
        u.role,
        u.is_active,
        u.is_verified,
        u.created_at,
        u.updated_at,
        u.ingestion_timestamp,
        u.source_system

    FROM silver.users u

),

-- ============================================================
-- ORDER METRICS
-- ============================================================

order_metrics AS (

    SELECT
        o.user_id,

        COUNT(*) AS total_orders,

        COUNT(*) FILTER (
            WHERE o.order_status = 'DELIVERED'
        ) AS delivered_orders,

        COUNT(*) FILTER (
            WHERE o.order_status = 'CANCELLED'
        ) AS cancelled_orders,

        COUNT(*) FILTER (
            WHERE o.payment_status = 'PAID'
        ) AS paid_orders,

        COALESCE(
            SUM(o.total_amount) FILTER (
                WHERE o.payment_status = 'PAID'
            ),
            0
        ) AS lifetime_value,

        COALESCE(
            AVG(o.total_amount) FILTER (
                WHERE o.payment_status = 'PAID'
            ),
            0
        ) AS average_order_value,

        COALESCE(
            SUM(o.total_quantity),
            0
        ) AS total_items_purchased,

        COALESCE(
            SUM(o.discount_amount),
            0
        ) AS total_order_discount,

        MIN(o.order_date) AS first_order_date,

        MAX(o.order_date) AS last_order_date,

        COUNT(DISTINCT o.order_date::date) AS order_days

    FROM silver.orders o

    GROUP BY o.user_id

),

-- ============================================================
-- EVENT / BEHAVIOR METRICS
-- ============================================================

event_metrics AS (

    SELECT
        e.user_id,

        COUNT(*) AS total_events,

        COUNT(DISTINCT e.session_id) AS total_sessions,

        COUNT(*) FILTER (
            WHERE e.event_type = 'LOGIN'
        ) AS login_events,

        COUNT(*) FILTER (
            WHERE e.event_type = 'VIEW_PRODUCT'
        ) AS product_views,

        COUNT(*) FILTER (
            WHERE e.event_type = 'ADD_TO_CART'
        ) AS cart_additions,

        COUNT(*) FILTER (
            WHERE e.event_type = 'REMOVE_FROM_CART'
        ) AS cart_removals,

        COUNT(*) FILTER (
            WHERE e.event_type = 'CHECKOUT_STARTED'
        ) AS checkout_started,

        COUNT(*) FILTER (
            WHERE e.event_type = 'PAYMENT_STARTED'
        ) AS payment_started,

        COUNT(*) FILTER (
            WHERE e.event_type = 'PURCHASE'
        ) AS purchase_events,

        COUNT(DISTINCT e.product_id) FILTER (
            WHERE e.product_id IS NOT NULL
        ) AS unique_products_interacted,

        MIN(e.event_timestamp) AS first_event_at,

        MAX(e.event_timestamp) AS last_event_at

    FROM silver.events e

    GROUP BY e.user_id

),

-- ============================================================
-- REVIEW METRICS
-- ============================================================

review_metrics AS (

    SELECT
        r.user_id,

        COUNT(*) AS total_reviews,

        ROUND(
            AVG(r.rating)::numeric,
            2
        ) AS average_rating_given,

        COUNT(*) FILTER (
            WHERE r.is_verified_purchase = TRUE
        ) AS verified_purchase_reviews,

        COUNT(*) FILTER (
            WHERE r.is_positive_review = TRUE
        ) AS positive_reviews,

        COUNT(*) FILTER (
            WHERE r.is_negative_review = TRUE
        ) AS negative_reviews,

        MAX(r.review_created_at) AS last_review_date

    FROM silver.reviews r

    WHERE r.is_approved = TRUE

    GROUP BY r.user_id

)

-- ============================================================
-- CUSTOMER 360
-- ============================================================

SELECT

    -- --------------------------------------------------------
    -- Customer identity
    -- --------------------------------------------------------

    c.user_id,
    c.username,
    c.email,
    c.last_name,
    c.country,
    c.currency,
    c.role,

    c.is_active,
    c.is_verified,

    c.created_at AS customer_created_at,

    -- --------------------------------------------------------
    -- Order metrics
    -- --------------------------------------------------------

    COALESCE(o.total_orders, 0) AS total_orders,

    COALESCE(o.delivered_orders, 0) AS delivered_orders,

    COALESCE(o.cancelled_orders, 0) AS cancelled_orders,

    COALESCE(o.paid_orders, 0) AS paid_orders,

    COALESCE(o.lifetime_value, 0) AS lifetime_value,

    COALESCE(o.average_order_value, 0) AS average_order_value,

    COALESCE(o.total_items_purchased, 0) AS total_items_purchased,

    COALESCE(o.total_order_discount, 0) AS total_order_discount,

    o.first_order_date,

    o.last_order_date,

    COALESCE(o.order_days, 0) AS order_days,

    -- --------------------------------------------------------
    -- Customer lifecycle
    -- --------------------------------------------------------

    CASE
        WHEN o.first_order_date IS NULL
            THEN NULL

        ELSE
            CURRENT_DATE - o.first_order_date::date
    END AS customer_lifetime_days,

    CASE
        WHEN o.last_order_date IS NULL
            THEN NULL

        ELSE
            CURRENT_DATE - o.last_order_date::date
    END AS days_since_last_order,

    -- --------------------------------------------------------
    -- Event / behavioral metrics
    -- --------------------------------------------------------

    COALESCE(e.total_events, 0) AS total_events,

    COALESCE(e.total_sessions, 0) AS total_sessions,

    COALESCE(e.login_events, 0) AS login_events,

    COALESCE(e.product_views, 0) AS product_views,

    COALESCE(e.cart_additions, 0) AS cart_additions,

    COALESCE(e.cart_removals, 0) AS cart_removals,

    COALESCE(e.checkout_started, 0) AS checkout_started,

    COALESCE(e.payment_started, 0) AS payment_started,

    COALESCE(e.purchase_events, 0) AS purchase_events,

    COALESCE(e.unique_products_interacted, 0)
        AS unique_products_interacted,

    e.first_event_at,

    e.last_event_at,

    -- --------------------------------------------------------
    -- Review metrics
    -- --------------------------------------------------------

    COALESCE(r.total_reviews, 0) AS total_reviews,

    r.average_rating_given,

    COALESCE(r.verified_purchase_reviews, 0)
        AS verified_purchase_reviews,

    COALESCE(r.positive_reviews, 0)
        AS positive_reviews,

    COALESCE(r.negative_reviews, 0)
        AS negative_reviews,

    r.last_review_date,

    -- --------------------------------------------------------
    -- Derived behavioral indicators
    -- --------------------------------------------------------

    CASE
        WHEN COALESCE(e.total_sessions, 0) > 0
        THEN ROUND(
            COALESCE(e.purchase_events, 0)::numeric
            / e.total_sessions,
            4
        )
        ELSE 0
    END AS session_to_purchase_rate,

    CASE
        WHEN COALESCE(e.product_views, 0) > 0
        THEN ROUND(
            COALESCE(e.cart_additions, 0)::numeric
            / e.product_views,
            4
        )
        ELSE 0
    END AS view_to_cart_rate,

    CASE
        WHEN COALESCE(e.checkout_started, 0) > 0
        THEN ROUND(
            COALESCE(e.purchase_events, 0)::numeric
            / e.checkout_started,
            4
        )
        ELSE 0
    END AS checkout_to_purchase_rate,

    -- --------------------------------------------------------
    -- Customer classification
    -- --------------------------------------------------------

    CASE

        WHEN COALESCE(o.total_orders, 0) = 0
             AND COALESCE(e.total_events, 0) = 0
            THEN 'INACTIVE'

        WHEN COALESCE(o.total_orders, 0) = 0
             AND COALESCE(e.total_events, 0) > 0
            THEN 'PROSPECT'

        WHEN COALESCE(o.total_orders, 0) = 1
            THEN 'NEW_CUSTOMER'

        WHEN COALESCE(o.total_orders, 0) BETWEEN 2 AND 3
            THEN 'REPEAT_CUSTOMER'

        WHEN COALESCE(o.total_orders, 0) >= 4
            THEN 'LOYAL_CUSTOMER'

        ELSE 'OTHER'

    END AS customer_segment,

    -- --------------------------------------------------------
    -- Engagement classification
    -- --------------------------------------------------------

    CASE

        WHEN COALESCE(e.total_events, 0) = 0
            THEN 'NO_ENGAGEMENT'

        WHEN COALESCE(e.total_events, 0) < 5
            THEN 'LOW_ENGAGEMENT'

        WHEN COALESCE(e.total_events, 0) < 15
            THEN 'MEDIUM_ENGAGEMENT'

        ELSE 'HIGH_ENGAGEMENT'

    END AS engagement_level,

    -- --------------------------------------------------------
    -- Purchase behavior
    -- --------------------------------------------------------

    CASE

        WHEN COALESCE(o.total_orders, 0) = 0
            THEN FALSE

        ELSE TRUE

    END AS has_purchased,

    CASE

        WHEN COALESCE(e.cart_additions, 0) > 0
             AND COALESCE(o.total_orders, 0) = 0
            THEN TRUE

        ELSE FALSE

    END AS has_abandoned_cart,

    CASE

        WHEN COALESCE(o.cancelled_orders, 0) > 0
            THEN TRUE

        ELSE FALSE

    END AS has_cancelled_order,

    CASE

        WHEN COALESCE(r.total_reviews, 0) > 0
            THEN TRUE

        ELSE FALSE

    END AS has_reviewed,

    -- --------------------------------------------------------
    -- Metadata
    -- --------------------------------------------------------

    CURRENT_TIMESTAMP AS gold_created_at

FROM customer_base c

LEFT JOIN order_metrics o
    ON c.user_id = o.user_id

LEFT JOIN event_metrics e
    ON c.user_id = e.user_id

LEFT JOIN review_metrics r
    ON c.user_id = r.user_id;


-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_gold_customer_360_user
ON gold.customer_360(user_id);

CREATE INDEX idx_gold_customer_360_country
ON gold.customer_360(country);

CREATE INDEX idx_gold_customer_360_segment
ON gold.customer_360(customer_segment);

CREATE INDEX idx_gold_customer_360_lifetime_value
ON gold.customer_360(lifetime_value);

CREATE INDEX idx_gold_customer_360_last_order
ON gold.customer_360(last_order_date);


-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE gold.customer_360 IS
'Customer-level analytical view combining customer profile, orders, behavioral events and reviews.';

COMMENT ON COLUMN gold.customer_360.lifetime_value IS
'Total paid order value generated by the customer.';

COMMENT ON COLUMN gold.customer_360.customer_segment IS
'Customer lifecycle segment based on purchasing behavior.';

COMMENT ON COLUMN gold.customer_360.engagement_level IS
'Customer engagement level based on behavioral event volume.';

COMMENT ON COLUMN gold.customer_360.has_abandoned_cart IS
'Indicates customers who added products to cart but have no recorded purchase.';

COMMENT ON COLUMN gold.customer_360.session_to_purchase_rate IS
'Ratio between purchase events and customer sessions.';

COMMENT ON COLUMN gold.customer_360.view_to_cart_rate IS
'Ratio between cart additions and product views.';

COMMENT ON COLUMN gold.customer_360.checkout_to_purchase_rate IS
'Ratio between purchase events and checkout starts.';