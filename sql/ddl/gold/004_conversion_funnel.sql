-- ============================================================
-- GOLD: CONVERSION FUNNEL
-- ============================================================
-- Purpose:
-- Daily customer funnel analytics combining:
--   1. Behavioral events from silver.events
--   2. Actual paid orders from silver.orders
--
-- Important:
-- Event tracking and transactional orders are intentionally
-- kept as separate concepts.
--
-- This allows us to detect:
--   - Missing PURCHASE events
--   - PURCHASE events without paid orders
--   - PAYMENT_STARTED without CHECKOUT_STARTED
--   - CHECKOUT_STARTED without ADD_TO_CART
--   - ADD_TO_CART without VIEW_PRODUCT
--
-- Grain:
--   One row per event_date
-- ============================================================


DROP TABLE IF EXISTS gold.conversion_funnel;


CREATE TABLE gold.conversion_funnel AS

WITH
-- ============================================================
-- 1. VALID EVENTS
-- ============================================================

valid_events AS (

    SELECT
        event_id,
        user_id,
        product_id,
        session_id,
        event_type,
        event_timestamp,
        event_date

    FROM silver.events

    WHERE deleted_at IS NULL
      AND event_type IN (
            'LOGIN',
            'VIEW_PRODUCT',
            'ADD_TO_CART',
            'CHECKOUT_STARTED',
            'PAYMENT_STARTED',
            'PURCHASE'
      )
),

-- ============================================================
-- 2. DAILY EVENT METRICS
-- ============================================================

daily_events AS (

    SELECT

        event_date,

        -- ----------------------------------------------------
        -- Unique users by funnel stage
        -- ----------------------------------------------------

        COUNT(DISTINCT user_id)
            FILTER (
                WHERE event_type = 'LOGIN'
            ) AS login_users,

        COUNT(DISTINCT user_id)
            FILTER (
                WHERE event_type = 'VIEW_PRODUCT'
            ) AS product_view_users,

        COUNT(DISTINCT user_id)
            FILTER (
                WHERE event_type = 'ADD_TO_CART'
            ) AS cart_users,

        COUNT(DISTINCT user_id)
            FILTER (
                WHERE event_type = 'CHECKOUT_STARTED'
            ) AS checkout_users,

        COUNT(DISTINCT user_id)
            FILTER (
                WHERE event_type = 'PAYMENT_STARTED'
            ) AS payment_users,

        COUNT(DISTINCT user_id)
            FILTER (
                WHERE event_type = 'PURCHASE'
            ) AS purchase_users,

        -- ----------------------------------------------------
        -- Raw event counts
        -- ----------------------------------------------------

        COUNT(*)
            FILTER (
                WHERE event_type = 'LOGIN'
            ) AS login_events,

        COUNT(*)
            FILTER (
                WHERE event_type = 'VIEW_PRODUCT'
            ) AS product_view_events,

        COUNT(*)
            FILTER (
                WHERE event_type = 'ADD_TO_CART'
            ) AS cart_events,

        COUNT(*)
            FILTER (
                WHERE event_type = 'CHECKOUT_STARTED'
            ) AS checkout_events,

        COUNT(*)
            FILTER (
                WHERE event_type = 'PAYMENT_STARTED'
            ) AS payment_events,

        COUNT(*)
            FILTER (
                WHERE event_type = 'PURCHASE'
            ) AS purchase_events

    FROM valid_events

    GROUP BY event_date
),

-- ============================================================
-- 3. DAILY PAID ORDERS
-- ============================================================

daily_orders AS (

    SELECT

        order_date::date AS event_date,

        COUNT(*) AS paid_orders,

        COUNT(DISTINCT user_id) AS paid_order_users,

        ROUND(
            SUM(total_amount),
            2
        ) AS paid_order_revenue

    FROM silver.orders

    WHERE payment_status = 'PAID'

      AND order_status NOT IN (
            'CANCELLED',
            'REFUNDED'
      )

    GROUP BY order_date::date
),

-- ============================================================
-- 4. EVENT SEQUENCE ANALYSIS
-- ============================================================
-- We evaluate whether users reached each previous funnel
-- stage before reaching the next stage.
--
-- This is more meaningful than simply comparing daily counts.
-- ============================================================

user_daily_funnel AS (

    SELECT

        event_date,
        user_id,

        -- ----------------------------------------------------
        -- Stage presence
        -- ----------------------------------------------------

        MAX(
            CASE
                WHEN event_type = 'LOGIN'
                THEN 1 ELSE 0
            END
        ) AS has_login,

        MAX(
            CASE
                WHEN event_type = 'VIEW_PRODUCT'
                THEN 1 ELSE 0
            END
        ) AS has_product_view,

        MAX(
            CASE
                WHEN event_type = 'ADD_TO_CART'
                THEN 1 ELSE 0
            END
        ) AS has_cart,

        MAX(
            CASE
                WHEN event_type = 'CHECKOUT_STARTED'
                THEN 1 ELSE 0
            END
        ) AS has_checkout,

        MAX(
            CASE
                WHEN event_type = 'PAYMENT_STARTED'
                THEN 1 ELSE 0
            END
        ) AS has_payment,

        MAX(
            CASE
                WHEN event_type = 'PURCHASE'
                THEN 1 ELSE 0
            END
        ) AS has_purchase

    FROM valid_events

    GROUP BY
        event_date,
        user_id
),

-- ============================================================
-- 5. DATA QUALITY / TRACKING GAPS
-- ============================================================

tracking_quality AS (

    SELECT

        event_date,

        -- ----------------------------------------------------
        -- PURCHASE without PAYMENT_STARTED
        -- ----------------------------------------------------

        COUNT(*)
            FILTER (
                WHERE has_purchase = 1
                  AND has_payment = 0
            ) AS purchase_without_payment_users,

        -- ----------------------------------------------------
        -- PAYMENT_STARTED without CHECKOUT_STARTED
        -- ----------------------------------------------------

        COUNT(*)
            FILTER (
                WHERE has_payment = 1
                  AND has_checkout = 0
            ) AS payment_without_checkout_users,

        -- ----------------------------------------------------
        -- CHECKOUT without CART
        -- ----------------------------------------------------

        COUNT(*)
            FILTER (
                WHERE has_checkout = 1
                  AND has_cart = 0
            ) AS checkout_without_cart_users,

        -- ----------------------------------------------------
        -- CART without PRODUCT VIEW
        -- ----------------------------------------------------

        COUNT(*)
            FILTER (
                WHERE has_cart = 1
                  AND has_product_view = 0
            ) AS cart_without_product_view_users

    FROM user_daily_funnel

    GROUP BY event_date
),

-- ============================================================
-- 6. PURCHASE TRACKING GAP
-- ============================================================
-- A paid order exists but the corresponding PURCHASE event
-- was not recorded on the same date.
-- ============================================================

purchase_tracking AS (

    SELECT

        o.event_date,

        COUNT(DISTINCT o.user_id)
            FILTER (
                WHERE e.user_id IS NULL
            ) AS purchase_tracking_gap_users

    FROM (

        SELECT

            order_date::date AS event_date,
            user_id

        FROM silver.orders

        WHERE payment_status = 'PAID'

          AND order_status NOT IN (
                'CANCELLED',
                'REFUNDED'
          )

        GROUP BY
            order_date::date,
            user_id

    ) o

    LEFT JOIN (

        SELECT DISTINCT

            event_date,
            user_id

        FROM valid_events

        WHERE event_type = 'PURCHASE'

    ) e

        ON e.event_date = o.event_date
       AND e.user_id = o.user_id

    GROUP BY
        o.event_date
)

-- ============================================================
-- 7. FINAL GOLD DATASET
-- ============================================================

SELECT

    -- ========================================================
    -- Date
    -- ========================================================

    e.event_date,

    -- ========================================================
    -- Funnel users
    -- ========================================================

    e.login_users,

    e.product_view_users,

    e.cart_users,

    e.checkout_users,

    e.payment_users,

    e.purchase_users,

    -- ========================================================
    -- Funnel conversion rates
    -- ========================================================

    ROUND(
        CASE
            WHEN e.login_users > 0
            THEN
                e.product_view_users::numeric
                / e.login_users * 100
            ELSE 0
        END,
        2
    ) AS login_to_view_rate,

    ROUND(
        CASE
            WHEN e.product_view_users > 0
            THEN
                e.cart_users::numeric
                / e.product_view_users * 100
            ELSE 0
        END,
        2
    ) AS view_to_cart_rate,

    ROUND(
        CASE
            WHEN e.cart_users > 0
            THEN
                e.checkout_users::numeric
                / e.cart_users * 100
            ELSE 0
        END,
        2
    ) AS cart_to_checkout_rate,

    ROUND(
        CASE
            WHEN e.checkout_users > 0
            THEN
                e.payment_users::numeric
                / e.checkout_users * 100
            ELSE 0
        END,
        2
    ) AS checkout_to_payment_rate,

    ROUND(
        CASE
            WHEN e.payment_users > 0
            THEN
                e.purchase_users::numeric
                / e.payment_users * 100
            ELSE 0
        END,
        2
    ) AS payment_to_purchase_rate,

    -- ========================================================
    -- Overall event-based conversion
    -- ========================================================

    ROUND(
        CASE
            WHEN e.login_users > 0
            THEN
                e.purchase_users::numeric
                / e.login_users * 100
            ELSE 0
        END,
        2
    ) AS overall_conversion_rate,

    -- ========================================================
    -- Funnel drop-off
    -- ========================================================

    e.login_users
        - e.product_view_users
        AS login_to_view_dropoff,

    e.product_view_users
        - e.cart_users
        AS view_to_cart_dropoff,

    e.cart_users
        - e.checkout_users
        AS cart_to_checkout_dropoff,

    e.checkout_users
        - e.payment_users
        AS checkout_to_payment_dropoff,

    e.payment_users
        - e.purchase_users
        AS payment_to_purchase_dropoff,

    -- ========================================================
    -- Raw events
    -- ========================================================

    e.login_events,

    e.product_view_events,

    e.cart_events,

    e.checkout_events,

    e.payment_events,

    e.purchase_events,

    -- ========================================================
    -- Tracking quality
    -- ========================================================

    COALESCE(
        tq.purchase_without_payment_users,
        0
    ) AS purchase_without_payment_users,

    COALESCE(
        tq.payment_without_checkout_users,
        0
    ) AS payment_without_checkout_users,

    COALESCE(
        tq.checkout_without_cart_users,
        0
    ) AS checkout_without_cart_users,

    COALESCE(
        tq.cart_without_product_view_users,
        0
    ) AS cart_without_product_view_users,

    -- ========================================================
    -- Actual transactional data
    -- ========================================================

    COALESCE(
        o.paid_orders,
        0
    ) AS paid_orders,

    COALESCE(
        o.paid_order_users,
        0
    ) AS paid_order_users,

    COALESCE(
        o.paid_order_revenue,
        0
    ) AS paid_order_revenue,

    -- ========================================================
    -- Event vs transaction discrepancy
    -- ========================================================

    COALESCE(
        pt.purchase_tracking_gap_users,
        0
    ) AS purchase_tracking_gap_users,

    -- ========================================================
    -- Metadata
    -- ========================================================

    CURRENT_TIMESTAMP AS gold_created_at

FROM daily_events e

LEFT JOIN daily_orders o
    ON o.event_date = e.event_date

LEFT JOIN tracking_quality tq
    ON tq.event_date = e.event_date

LEFT JOIN purchase_tracking pt
    ON pt.event_date = e.event_date

ORDER BY
    e.event_date;


-- ============================================================
-- INDEXES
-- ============================================================

CREATE UNIQUE INDEX idx_gold_conversion_funnel_date
ON gold.conversion_funnel(event_date);

CREATE INDEX idx_gold_conversion_funnel_conversion
ON gold.conversion_funnel(overall_conversion_rate);

CREATE INDEX idx_gold_conversion_funnel_paid_orders
ON gold.conversion_funnel(paid_orders);

CREATE INDEX idx_gold_conversion_funnel_tracking_gap
ON gold.conversion_funnel(purchase_tracking_gap_users);


-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE gold.conversion_funnel IS
'Daily ecommerce conversion funnel combining behavioral events, transactional orders and tracking-quality metrics.';

COMMENT ON COLUMN gold.conversion_funnel.overall_conversion_rate IS
'Percentage of logged-in users who generated a PURCHASE event on the same date.';

COMMENT ON COLUMN gold.conversion_funnel.paid_orders IS
'Number of paid, non-cancelled and non-refunded orders recorded on the date.';

COMMENT ON COLUMN gold.conversion_funnel.paid_order_revenue IS
'Revenue generated by paid, non-cancelled and non-refunded orders.';

COMMENT ON COLUMN gold.conversion_funnel.purchase_without_payment_users IS
'Users with a PURCHASE event but without a PAYMENT_STARTED event on the same date.';

COMMENT ON COLUMN gold.conversion_funnel.payment_without_checkout_users IS
'Users with PAYMENT_STARTED but without CHECKOUT_STARTED on the same date.';

COMMENT ON COLUMN gold.conversion_funnel.checkout_without_cart_users IS
'Users with CHECKOUT_STARTED but without ADD_TO_CART on the same date.';

COMMENT ON COLUMN gold.conversion_funnel.cart_without_product_view_users IS
'Users with ADD_TO_CART but without VIEW_PRODUCT on the same date.';

COMMENT ON COLUMN gold.conversion_funnel.purchase_tracking_gap_users IS
'Users with a paid order but without a PURCHASE event recorded on the same date.';