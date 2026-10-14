-- ============================================================
-- DBT MART
-- customer_360.sql
-- Customer-level analytical model
-- ============================================================

WITH customer_base AS (

    SELECT
        user_id,
        username,
        email,
        last_name,
        country,
        currency,
        role,
        is_verified,
        created_at,
        updated_at,
        ingestion_timestamp,
        source_system

    FROM {{ ref('stg_users') }}

),

-- ============================================================
-- ORDER METRICS
-- ============================================================

order_metrics AS (

    SELECT
        user_id,

        COUNT(*) AS total_orders,

        COUNT(*) FILTER (
            WHERE order_status = 'DELIVERED'
        ) AS delivered_orders,

        COUNT(*) FILTER (
            WHERE order_status = 'CANCELLED'
        ) AS cancelled_orders,

        COUNT(*) FILTER (
            WHERE payment_status = 'PAID'
        ) AS paid_orders,

        COALESCE(
            SUM(total_amount) FILTER (
                WHERE payment_status = 'PAID'
            ),
            0
        ) AS lifetime_value,

        COALESCE(
            AVG(total_amount) FILTER (
                WHERE payment_status = 'PAID'
            ),
            0
        ) AS average_order_value,

        COALESCE(
            SUM(discount_amount),
            0
        ) AS total_order_discount,

        MIN(order_date) AS first_order_date,

        MAX(order_date) AS last_order_date,

        COUNT(DISTINCT order_date::date) AS order_days

    FROM {{ ref('stg_orders') }}

    GROUP BY user_id

),

-- ============================================================
-- EVENT / BEHAVIOR METRICS
-- ============================================================

event_metrics AS (

    SELECT
        user_id,

        COUNT(*) AS total_events,

        COUNT(DISTINCT session_id) AS total_sessions,

        COUNT(*) FILTER (
            WHERE event_type = 'LOGIN'
        ) AS login_events,

        COUNT(*) FILTER (
            WHERE event_type = 'VIEW_PRODUCT'
        ) AS product_views,

        COUNT(*) FILTER (
            WHERE event_type = 'ADD_TO_CART'
        ) AS cart_additions,

        COUNT(*) FILTER (
            WHERE event_type = 'REMOVE_FROM_CART'
        ) AS cart_removals,

        COUNT(*) FILTER (
            WHERE event_type = 'CHECKOUT_STARTED'
        ) AS checkout_started,

        COUNT(*) FILTER (
            WHERE event_type = 'PAYMENT_STARTED'
        ) AS payment_started,

        COUNT(*) FILTER (
            WHERE event_type = 'PURCHASE'
        ) AS purchase_events,

        COUNT(DISTINCT product_id) FILTER (
            WHERE product_id IS NOT NULL
        ) AS unique_products_interacted,

        MIN(event_timestamp) AS first_event_at,

        MAX(event_timestamp) AS last_event_at

    FROM {{ ref('stg_events') }}

    GROUP BY user_id

),

-- ============================================================
-- REVIEW METRICS
-- ============================================================

review_metrics AS (

    SELECT
        user_id,

        COUNT(*) AS total_reviews,

        ROUND(
            AVG(rating)::numeric,
            2
        ) AS average_rating_given,

        COUNT(*) FILTER (
            WHERE is_verified_purchase = TRUE
        ) AS verified_purchase_reviews,

        COUNT(*) FILTER (
            WHERE rating >= 4
        ) AS positive_reviews,

        COUNT(*) FILTER (
            WHERE rating <= 2
        ) AS negative_reviews,

        MAX(created_at) AS last_review_date

    FROM {{ ref('stg_reviews') }}

    WHERE is_approved = TRUE

    GROUP BY user_id

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

    COALESCE(
        e.unique_products_interacted,
        0
    ) AS unique_products_interacted,

    e.first_event_at,

    e.last_event_at,

    -- --------------------------------------------------------
    -- Review metrics
    -- --------------------------------------------------------

    COALESCE(r.total_reviews, 0) AS total_reviews,

    r.average_rating_given,

    COALESCE(
        r.verified_purchase_reviews,
        0
    ) AS verified_purchase_reviews,

    COALESCE(
        r.positive_reviews,
        0
    ) AS positive_reviews,

    COALESCE(
        r.negative_reviews,
        0
    ) AS negative_reviews,

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

    CURRENT_TIMESTAMP AS dbt_created_at

FROM customer_base c

LEFT JOIN order_metrics o
    ON c.user_id = o.user_id

LEFT JOIN event_metrics e
    ON c.user_id = e.user_id

LEFT JOIN review_metrics r
    ON c.user_id = r.user_id