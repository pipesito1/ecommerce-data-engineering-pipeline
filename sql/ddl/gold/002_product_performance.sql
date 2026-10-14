-- ============================================================
-- GOLD LAYER
-- 002_product_performance.sql
-- ============================================================

DROP TABLE IF EXISTS gold.product_performance;

CREATE TABLE gold.product_performance AS

WITH sales AS (

    SELECT
        pv.product_id,

        COUNT(DISTINCT o.order_id) AS total_orders,

        COUNT(DISTINCT o.user_id) AS unique_customers,

        SUM(oi.quantity) AS units_sold,

        SUM(
            oi.unit_price * oi.quantity
        ) AS gross_revenue,

        SUM(
            COALESCE(oi.discount_amount, 0)
        ) AS discount_amount,

        SUM(
            oi.total_price
        ) AS net_revenue,

        ROUND(
            SUM(oi.total_price)
            / NULLIF(SUM(oi.quantity), 0),
            2
        ) AS avg_selling_price,

        SUM(
            oi.total_price
            - (p.cost_price * oi.quantity)
        ) AS estimated_gross_profit

    FROM silver.orders o

    INNER JOIN bronze.order_items oi
        ON oi.order_id = o.order_id

    INNER JOIN bronze.product_variants pv
        ON pv.variant_id = oi.variant_id

    INNER JOIN silver.products p
        ON p.product_id = pv.product_id

    WHERE o.cancelled_at IS NULL
      AND o.order_status <> 'CANCELLED'
      AND oi.deleted_at IS NULL

    GROUP BY pv.product_id
),

events AS (

    SELECT
        product_id,

        COUNT(*) AS total_events,

        COUNT(*) FILTER (
            WHERE event_type = 'VIEW_PRODUCT'
        ) AS product_views,

        COUNT(*) FILTER (
            WHERE event_type = 'ADD_TO_CART'
        ) AS cart_additions,

        COUNT(*) FILTER (
            WHERE event_type = 'CHECKOUT_STARTED'
        ) AS checkout_started,

        COUNT(*) FILTER (
            WHERE event_type = 'PAYMENT_STARTED'
        ) AS payment_started,

        COUNT(*) FILTER (
            WHERE event_type = 'PURCHASE'
        ) AS purchase_events

    FROM silver.events

    WHERE product_id IS NOT NULL

    GROUP BY product_id
),

reviews AS (

    SELECT
        product_id,

        COUNT(*) AS total_reviews,

        ROUND(
            AVG(rating),
            2
        ) AS avg_review_rating,

        COUNT(*) FILTER (
            WHERE rating >= 4
        ) AS positive_reviews,

        COUNT(*) FILTER (
            WHERE rating <= 2
        ) AS negative_reviews,

        COUNT(*) FILTER (
            WHERE is_verified_purchase = TRUE
        ) AS verified_reviews

    FROM silver.reviews

    WHERE is_approved = TRUE
      AND deleted_at IS NULL

    GROUP BY product_id
)

SELECT

    -- ========================================================
    -- Product information
    -- ========================================================

    p.product_id,
    p.sku,
    p.product_name,

    p.category_id,
    p.category_name,

    p.brand_id,
    p.brand_name,

    p.supplier_id,
    p.supplier_name,

    p.currency,

    -- ========================================================
    -- Pricing
    -- ========================================================

    p.cost_price,
    p.sale_price,

    ROUND(
        p.sale_price - p.cost_price,
        2
    ) AS unit_margin,

    ROUND(
        CASE
            WHEN p.sale_price > 0
            THEN (
                (p.sale_price - p.cost_price)
                / p.sale_price
            ) * 100
            ELSE 0
        END,
        2
    ) AS margin_percentage,

    -- ========================================================
    -- Sales metrics
    -- ========================================================

    COALESCE(s.total_orders, 0) AS total_orders,

    COALESCE(s.unique_customers, 0) AS unique_customers,

    COALESCE(s.units_sold, 0) AS units_sold,

    COALESCE(s.gross_revenue, 0) AS gross_revenue,

    COALESCE(s.discount_amount, 0) AS discount_amount,

    COALESCE(s.net_revenue, 0) AS net_revenue,

    COALESCE(s.avg_selling_price, 0) AS avg_selling_price,

    COALESCE(
        s.estimated_gross_profit,
        0
    ) AS estimated_gross_profit,

    -- ========================================================
    -- Customer behavior
    -- ========================================================

    COALESCE(e.total_events, 0) AS total_events,

    COALESCE(e.product_views, 0) AS product_views,

    COALESCE(e.cart_additions, 0) AS cart_additions,

    COALESCE(e.checkout_started, 0) AS checkout_started,

    COALESCE(e.payment_started, 0) AS payment_started,

    COALESCE(e.purchase_events, 0) AS purchase_events,

    -- ========================================================
    -- Conversion metrics
    -- ========================================================

    ROUND(
        CASE
            WHEN COALESCE(e.product_views, 0) > 0
            THEN (
                COALESCE(e.cart_additions, 0)::numeric
                / e.product_views
            ) * 100
            ELSE 0
        END,
        2
    ) AS view_to_cart_rate,

    ROUND(
        CASE
            WHEN COALESCE(e.cart_additions, 0) > 0
            THEN (
                COALESCE(e.purchase_events, 0)::numeric
                / e.cart_additions
            ) * 100
            ELSE 0
        END,
        2
    ) AS cart_to_purchase_rate,

    ROUND(
        CASE
            WHEN COALESCE(e.product_views, 0) > 0
            THEN (
                COALESCE(e.purchase_events, 0)::numeric
                / e.product_views
            ) * 100
            ELSE 0
        END,
        2
    ) AS view_to_purchase_rate,

    -- ========================================================
    -- Reviews
    -- ========================================================

    COALESCE(r.total_reviews, 0) AS total_reviews,

    COALESCE(r.avg_review_rating, 0) AS avg_review_rating,

    COALESCE(r.positive_reviews, 0) AS positive_reviews,

    COALESCE(r.negative_reviews, 0) AS negative_reviews,

    COALESCE(r.verified_reviews, 0) AS verified_reviews,

    -- ========================================================
    -- Inventory
    -- ========================================================

    p.stock_quantity,

    p.low_stock_threshold,

    CASE
        WHEN p.stock_quantity = 0
            THEN 'OUT_OF_STOCK'

        WHEN p.stock_quantity <= p.low_stock_threshold
            THEN 'LOW_STOCK'

        ELSE 'IN_STOCK'
    END AS stock_status,

    p.backorder_allowed,

    p.is_active,

    p.is_featured,

    -- ========================================================
    -- Product classification
    -- ========================================================

    CASE
        WHEN COALESCE(s.net_revenue, 0) > 0
            THEN 'SELLING'

        WHEN COALESCE(e.product_views, 0) > 0
            THEN 'VIEWED_NOT_SOLD'

        ELSE 'NO_ACTIVITY'
    END AS product_status,

    -- ========================================================
    -- Metadata
    -- ========================================================

    CURRENT_TIMESTAMP AS gold_created_at

FROM silver.products p

LEFT JOIN sales s
    ON s.product_id = p.product_id

LEFT JOIN events e
    ON e.product_id = p.product_id

LEFT JOIN reviews r
    ON r.product_id = p.product_id;


-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_gold_product_performance_product
ON gold.product_performance(product_id);

CREATE INDEX idx_gold_product_performance_category
ON gold.product_performance(category_id);

CREATE INDEX idx_gold_product_performance_brand
ON gold.product_performance(brand_id);

CREATE INDEX idx_gold_product_performance_revenue
ON gold.product_performance(net_revenue);

CREATE INDEX idx_gold_product_performance_status
ON gold.product_performance(product_status);


-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE gold.product_performance IS
'Gold-level product performance combining sales, customer behavior, conversion, reviews and inventory metrics.';

COMMENT ON COLUMN gold.product_performance.net_revenue IS
'Revenue after item-level discounts from non-cancelled orders.';

COMMENT ON COLUMN gold.product_performance.view_to_purchase_rate IS
'Percentage of product views that resulted in a purchase event.';

COMMENT ON COLUMN gold.product_performance.stock_status IS
'Inventory classification based on stock quantity and low-stock threshold.';