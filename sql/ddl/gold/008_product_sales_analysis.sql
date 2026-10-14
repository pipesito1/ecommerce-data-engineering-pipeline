-- ============================================================
-- GOLD: PRODUCT SALES ANALYSIS
-- ============================================================
-- Purpose:
--     Business-oriented analysis of product sales performance.
--
-- Grain:
--     One row per product.
--
-- Source:
--     gold.product_performance
--
-- ============================================================

DROP TABLE IF EXISTS gold.product_sales_analysis;

CREATE TABLE gold.product_sales_analysis AS

WITH base AS (

    SELECT
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
        unit_margin,
        margin_percentage,

        total_orders,
        unique_customers,
        units_sold,

        gross_revenue,
        discount_amount,
        net_revenue,
        avg_selling_price,
        estimated_gross_profit,

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
        avg_review_rating,
        positive_reviews,
        negative_reviews,
        verified_reviews,

        stock_quantity,
        low_stock_threshold,
        stock_status,
        backorder_allowed,

        is_active,
        is_featured,
        product_status

    FROM gold.product_performance
),

classified AS (

    SELECT
        b.*,

        -- Revenue generated per customer
        CASE
            WHEN unique_customers > 0
            THEN ROUND(
                net_revenue / unique_customers,
                2
            )
            ELSE 0
        END AS revenue_per_customer,

        -- Revenue generated per order
        CASE
            WHEN total_orders > 0
            THEN ROUND(
                net_revenue / total_orders,
                2
            )
            ELSE 0
        END AS revenue_per_order,

        -- Actual gross margin percentage
        CASE
            WHEN net_revenue > 0
            THEN ROUND(
                (estimated_gross_profit / net_revenue) * 100,
                2
            )
            ELSE 0
        END AS gross_margin_rate,

        -- Sales velocity
        CASE
            WHEN total_orders > 0
            THEN ROUND(
                units_sold::numeric / total_orders,
                2
            )
            ELSE 0
        END AS units_per_order,

        -- Demand / conversion classification
        CASE

            WHEN product_views > 0
                 AND purchase_events = 0
            THEN 'HIGH_INTEREST_NO_PURCHASE'

            WHEN product_views > 0
                 AND purchase_events > 0
                 AND view_to_purchase_rate < 5
            THEN 'LOW_CONVERSION'

            WHEN product_views > 0
                 AND purchase_events > 0
                 AND view_to_purchase_rate >= 5
            THEN 'GOOD_CONVERSION'

            WHEN units_sold > 0
                 AND product_views = 0
            THEN 'SALES_WITHOUT_TRACKED_VIEWS'

            ELSE 'NO_DEMAND'

        END AS sales_conversion_status,

        -- Inventory + sales relationship
        CASE

            WHEN stock_quantity = 0
                 AND units_sold > 0
            THEN 'OUT_OF_STOCK_SELLER'

            WHEN stock_quantity <= low_stock_threshold
                 AND units_sold > 0
            THEN 'SELLING_LOW_STOCK'

            WHEN stock_quantity <= low_stock_threshold
                 AND units_sold = 0
            THEN 'LOW_STOCK_NO_SALES'

            WHEN stock_quantity > low_stock_threshold
            THEN 'HEALTHY_STOCK'

            ELSE 'UNKNOWN'

        END AS inventory_sales_status

    FROM base b
),

segmented AS (

    SELECT
        c.*,

        -- Main product sales segment
        CASE

            WHEN units_sold > 0
                 AND net_revenue > 0
                 AND gross_margin_rate >= 40
            THEN 'HIGH_VALUE_PRODUCT'

            WHEN units_sold > 0
                 AND net_revenue > 0
            THEN 'STANDARD_SELLER'

            WHEN product_views > 0
                 AND purchase_events = 0
            THEN 'OPPORTUNITY'

            WHEN product_views > 0
                 AND purchase_events > 0
            THEN 'LOW_PERFORMING_SELLER'

            ELSE 'NO_SALES'

        END AS product_sales_segment,

        -- Business priority
        CASE

            WHEN units_sold > 0
                 AND gross_margin_rate >= 40
                 AND stock_quantity <= low_stock_threshold
            THEN 'CRITICAL'

            WHEN units_sold > 0
                 AND gross_margin_rate >= 40
            THEN 'HIGH'

            WHEN product_views > 0
                 AND purchase_events = 0
            THEN 'MEDIUM'

            WHEN units_sold > 0
            THEN 'STANDARD'

            ELSE 'LOW'

        END AS business_priority

    FROM classified c
)

SELECT

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
    unit_margin,
    margin_percentage,

    total_orders,
    unique_customers,
    units_sold,

    gross_revenue,
    discount_amount,
    net_revenue,

    avg_selling_price,
    estimated_gross_profit,

    revenue_per_customer,
    revenue_per_order,
    gross_margin_rate,
    units_per_order,

    total_events,
    product_views,
    cart_additions,
    checkout_started,
    payment_started,
    purchase_events,

    view_to_cart_rate,
    cart_to_purchase_rate,
    view_to_purchase_rate,

    sales_conversion_status,

    total_reviews,
    avg_review_rating,
    positive_reviews,
    negative_reviews,
    verified_reviews,

    stock_quantity,
    low_stock_threshold,
    stock_status,
    backorder_allowed,

    inventory_sales_status,

    is_active,
    is_featured,
    product_status,

    product_sales_segment,
    business_priority,

    CURRENT_TIMESTAMP AS gold_created_at

FROM segmented;


-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_product_sales_analysis_product
    ON gold.product_sales_analysis (product_id);

CREATE INDEX idx_product_sales_analysis_revenue
    ON gold.product_sales_analysis (net_revenue DESC);

CREATE INDEX idx_product_sales_analysis_segment
    ON gold.product_sales_analysis (product_sales_segment);

CREATE INDEX idx_product_sales_analysis_priority
    ON gold.product_sales_analysis (business_priority);


-- ============================================================
-- DOCUMENTATION
-- ============================================================

COMMENT ON TABLE gold.product_sales_analysis
IS 'Business-oriented product sales analysis derived from gold.product_performance.';

COMMENT ON COLUMN gold.product_sales_analysis.product_sales_segment
IS 'Business classification of products based on sales, revenue and customer demand.';

COMMENT ON COLUMN gold.product_sales_analysis.business_priority
IS 'Business priority for commercial and inventory actions.';

COMMENT ON COLUMN gold.product_sales_analysis.sales_conversion_status
IS 'Classification of product demand based on product views and purchases.';

COMMENT ON COLUMN gold.product_sales_analysis.inventory_sales_status
IS 'Inventory condition evaluated together with product sales activity.';

COMMENT ON COLUMN gold.product_sales_analysis.gross_margin_rate
IS 'Estimated gross profit as a percentage of net revenue.';