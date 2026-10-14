-- ============================================================
-- GOLD: CATEGORY PERFORMANCE
-- ============================================================
-- Purpose:
--     Business performance analysis at category level.
--
-- Grain:
--     One row per product category.
--
-- Source:
--     gold.product_sales_analysis
--
-- Main questions:
--     - Which categories generate the most revenue?
--     - Which categories sell the most units?
--     - Which categories have the best margins?
--     - Which categories have the strongest conversion?
--     - Which categories have customer interest but weak sales?
--     - Which categories require commercial attention?
--
-- ============================================================

DROP TABLE IF EXISTS gold.category_performance;

CREATE TABLE gold.category_performance AS

WITH category_base AS (

    SELECT
        category_id,
        category_name,

        COUNT(DISTINCT product_id) AS product_count,

        COUNT(DISTINCT CASE
            WHEN units_sold > 0 THEN product_id
        END) AS selling_product_count,

        COUNT(DISTINCT CASE
            WHEN product_views > 0 THEN product_id
        END) AS viewed_product_count,

        COUNT(DISTINCT CASE
            WHEN product_views > 0
             AND purchase_events = 0
            THEN product_id
        END) AS opportunity_product_count,

        SUM(total_orders) AS total_orders,
        SUM(unique_customers) AS unique_customers,
        SUM(units_sold) AS units_sold,

        SUM(gross_revenue) AS gross_revenue,
        SUM(discount_amount) AS discount_amount,
        SUM(net_revenue) AS net_revenue,

        SUM(estimated_gross_profit) AS estimated_gross_profit,

        SUM(total_events) AS total_events,
        SUM(product_views) AS product_views,
        SUM(cart_additions) AS cart_additions,
        SUM(checkout_started) AS checkout_started,
        SUM(payment_started) AS payment_started,
        SUM(purchase_events) AS purchase_events,

        SUM(total_reviews) AS total_reviews,
        SUM(positive_reviews) AS positive_reviews,
        SUM(negative_reviews) AS negative_reviews,
        SUM(verified_reviews) AS verified_reviews,

        SUM(stock_quantity) AS total_stock_quantity,

        SUM(
            CASE
                WHEN stock_quantity <= low_stock_threshold
                THEN 1
                ELSE 0
            END
        ) AS low_stock_product_count,

        SUM(
            CASE
                WHEN units_sold > 0
                 AND stock_quantity <= low_stock_threshold
                THEN 1
                ELSE 0
            END
        ) AS selling_low_stock_product_count

    FROM gold.product_sales_analysis

    GROUP BY
        category_id,
        category_name
),

calculated AS (

    SELECT
        cb.*,

        -- Revenue per customer
        CASE
            WHEN unique_customers > 0
            THEN ROUND(
                net_revenue / unique_customers,
                2
            )
            ELSE 0
        END AS revenue_per_customer,

        -- Revenue per order
        CASE
            WHEN total_orders > 0
            THEN ROUND(
                net_revenue / total_orders,
                2
            )
            ELSE 0
        END AS revenue_per_order,

        -- Category gross margin
        CASE
            WHEN net_revenue > 0
            THEN ROUND(
                (estimated_gross_profit / net_revenue) * 100,
                2
            )
            ELSE 0
        END AS gross_margin_rate,

        -- View → purchase conversion
        CASE
            WHEN product_views > 0
            THEN ROUND(
                (purchase_events::numeric / product_views) * 100,
                2
            )
            ELSE 0
        END AS view_to_purchase_rate,

        -- View → cart conversion
        CASE
            WHEN product_views > 0
            THEN ROUND(
                (cart_additions::numeric / product_views) * 100,
                2
            )
            ELSE 0
        END AS view_to_cart_rate,

        -- Cart → purchase conversion
        CASE
            WHEN cart_additions > 0
            THEN ROUND(
                (purchase_events::numeric / cart_additions) * 100,
                2
            )
            ELSE 0
        END AS cart_to_purchase_rate,

        -- Average selling price
        CASE
            WHEN units_sold > 0
            THEN ROUND(
                net_revenue / units_sold,
                2
            )
            ELSE 0
        END AS average_selling_price

    FROM category_base cb
),

ranked AS (

    SELECT
        c.*,

        RANK() OVER (
            ORDER BY net_revenue DESC
        ) AS revenue_rank,

        RANK() OVER (
            ORDER BY units_sold DESC
        ) AS units_rank,

        RANK() OVER (
            ORDER BY gross_margin_rate DESC
        ) AS margin_rank,

        RANK() OVER (
            ORDER BY view_to_purchase_rate DESC
        ) AS conversion_rank

    FROM calculated c
),

segmented AS (

    SELECT
        r.*,

        CASE

            WHEN net_revenue > 0
             AND gross_margin_rate >= 40
             AND units_sold > 0
            THEN 'HIGH_PERFORMING_CATEGORY'

            WHEN net_revenue > 0
             AND units_sold > 0
            THEN 'STANDARD_PERFORMING_CATEGORY'

            WHEN product_views > 0
             AND purchase_events = 0
            THEN 'DEMAND_OPPORTUNITY'

            WHEN product_views > 0
             AND purchase_events > 0
             AND net_revenue = 0
            THEN 'TRACKING_GAP'

            ELSE 'NO_SALES_CATEGORY'

        END AS category_segment,

        CASE

            WHEN selling_low_stock_product_count > 0
             AND net_revenue > 0
            THEN 'CRITICAL'

            WHEN net_revenue > 0
             AND gross_margin_rate >= 40
            THEN 'HIGH'

            WHEN opportunity_product_count > 0
            THEN 'MEDIUM'

            WHEN net_revenue > 0
            THEN 'STANDARD'

            ELSE 'LOW'

        END AS business_priority

    FROM ranked r
)

SELECT

    category_id,
    category_name,

    product_count,
    selling_product_count,
    viewed_product_count,
    opportunity_product_count,

    total_orders,
    unique_customers,
    units_sold,

    gross_revenue,
    discount_amount,
    net_revenue,
    estimated_gross_profit,

    revenue_per_customer,
    revenue_per_order,
    average_selling_price,
    gross_margin_rate,

    total_events,
    product_views,
    cart_additions,
    checkout_started,
    payment_started,
    purchase_events,

    view_to_cart_rate,
    cart_to_purchase_rate,
    view_to_purchase_rate,

    total_reviews,
    positive_reviews,
    negative_reviews,
    verified_reviews,

    total_stock_quantity,
    low_stock_product_count,
    selling_low_stock_product_count,

    revenue_rank,
    units_rank,
    margin_rank,
    conversion_rank,

    category_segment,
    business_priority,

    CURRENT_TIMESTAMP AS gold_created_at

FROM segmented;


-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_category_performance_category
    ON gold.category_performance (category_id);

CREATE INDEX idx_category_performance_revenue
    ON gold.category_performance (net_revenue DESC);

CREATE INDEX idx_category_performance_segment
    ON gold.category_performance (category_segment);

CREATE INDEX idx_category_performance_priority
    ON gold.category_performance (business_priority);


-- ============================================================
-- DOCUMENTATION
-- ============================================================

COMMENT ON TABLE gold.category_performance
IS 'Business performance analysis aggregated at product category level.';

COMMENT ON COLUMN gold.category_performance.category_segment
IS 'Business classification of category performance based on revenue, margin, demand and sales activity.';

COMMENT ON COLUMN gold.category_performance.business_priority
IS 'Business priority for commercial and inventory actions.';

COMMENT ON COLUMN gold.category_performance.revenue_rank
IS 'Rank of the category based on net revenue.';

COMMENT ON COLUMN gold.category_performance.units_rank
IS 'Rank of the category based on units sold.';

COMMENT ON COLUMN gold.category_performance.margin_rank
IS 'Rank of the category based on gross margin rate.';

COMMENT ON COLUMN gold.category_performance.conversion_rank
IS 'Rank of the category based on view-to-purchase conversion.';