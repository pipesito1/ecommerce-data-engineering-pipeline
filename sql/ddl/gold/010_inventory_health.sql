-- ============================================================
-- GOLD: INVENTORY HEALTH
-- Purpose:
--   Evaluate product inventory health using current stock,
--   sales performance, demand signals and inventory value.
--
-- Sources:
--   gold.product_sales_analysis
--   silver.products
--
-- Grain:
--   One row per product.
-- ============================================================

DROP TABLE IF EXISTS gold.inventory_health;

CREATE TABLE gold.inventory_health AS

WITH base AS (

    SELECT
        psa.product_id,
        psa.sku,
        psa.product_name,
        psa.category_id,
        psa.category_name,
        psa.brand_id,
        psa.brand_name,
        psa.supplier_id,
        psa.supplier_name,

        psa.cost_price,
        psa.sale_price,
        psa.units_sold,
        psa.total_orders,
        psa.unique_customers,
        psa.net_revenue,
        psa.estimated_gross_profit,

        psa.total_events,
        psa.product_views,
        psa.cart_additions,
        psa.checkout_started,
        psa.payment_started,
        psa.purchase_events,

        psa.sales_conversion_status,
        psa.product_sales_segment,
        psa.business_priority,

        p.stock_quantity,
        p.low_stock_threshold,
        p.backorder_allowed,
        p.is_active,
        p.is_featured,

        p.created_at,
        p.updated_at

    FROM gold.product_sales_analysis psa

    INNER JOIN silver.products p
        ON psa.product_id = p.product_id
),

metrics AS (

    SELECT
        *,

        -- Current inventory value at cost
        ROUND(
            stock_quantity * COALESCE(cost_price, 0),
            2
        ) AS inventory_cost_value,

        -- Potential inventory revenue at current sale price
        ROUND(
            stock_quantity * COALESCE(sale_price, 0),
            2
        ) AS inventory_retail_value,

        -- Estimated gross profit if all current stock is sold
        ROUND(
            stock_quantity
            * GREATEST(
                COALESCE(sale_price, 0) - COALESCE(cost_price, 0),
                0
            ),
            2
        ) AS inventory_potential_profit,

        -- Stock coverage based on observed units sold.
        -- NULL when there has been no recorded demand.
        CASE
            WHEN units_sold > 0
                THEN ROUND(
                    stock_quantity::numeric / units_sold,
                    2
                )
            ELSE NULL
        END AS stock_to_sales_ratio

    FROM base
),

classified AS (

    SELECT
        *,

        CASE
            WHEN stock_quantity <= 0
                THEN 'OUT_OF_STOCK'

            WHEN stock_quantity <= low_stock_threshold
                THEN 'LOW_STOCK'

            WHEN units_sold = 0
                 AND product_views > 0
                THEN 'OVERSTOCK_RISK'

            WHEN units_sold = 0
                 AND total_events = 0
                THEN 'NO_DEMAND'

            ELSE 'HEALTHY_STOCK'
        END AS inventory_health_status,

        CASE
            WHEN stock_quantity <= 0
                AND units_sold > 0
                THEN 'URGENT_REPLENISHMENT'

            WHEN stock_quantity <= low_stock_threshold
                 AND units_sold > 0
                THEN 'HIGH_REPLENISHMENT_PRIORITY'

            WHEN units_sold > 0
                 AND stock_quantity > low_stock_threshold
                THEN 'MONITOR_DEMAND'

            WHEN units_sold = 0
                 AND product_views > 0
                THEN 'REVIEW_DEMAND'

            WHEN units_sold = 0
                 AND total_events = 0
                THEN 'NO_ACTION'

            ELSE 'MONITOR'
        END AS replenishment_priority,

        CASE
            WHEN units_sold > 0
                 AND stock_quantity <= low_stock_threshold
                THEN 'HIGH'

            WHEN units_sold > 0
                 AND stock_quantity > low_stock_threshold
                THEN 'MEDIUM'

            WHEN units_sold = 0
                 AND product_views > 0
                THEN 'MEDIUM'

            ELSE 'LOW'
        END AS inventory_business_priority

    FROM metrics
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

    cost_price,
    sale_price,

    stock_quantity,
    low_stock_threshold,

    units_sold,
    total_orders,
    unique_customers,

    net_revenue,
    estimated_gross_profit,

    total_events,
    product_views,
    cart_additions,
    checkout_started,
    payment_started,
    purchase_events,

    sales_conversion_status,
    product_sales_segment,
    business_priority,

    inventory_cost_value,
    inventory_retail_value,
    inventory_potential_profit,
    stock_to_sales_ratio,

    inventory_health_status,
    replenishment_priority,
    inventory_business_priority,

    backorder_allowed,
    is_active,
    is_featured,

    created_at,
    updated_at,

    CURRENT_TIMESTAMP AS gold_created_at

FROM classified;


-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_inventory_health_product
    ON gold.inventory_health(product_id);

CREATE INDEX idx_inventory_health_category
    ON gold.inventory_health(category_id);

CREATE INDEX idx_inventory_health_status
    ON gold.inventory_health(inventory_health_status);

CREATE INDEX idx_inventory_health_priority
    ON gold.inventory_health(replenishment_priority);


-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE gold.inventory_health IS
'Gold inventory health analysis by product, combining stock levels, demand signals, sales performance and inventory value.';

COMMENT ON COLUMN gold.inventory_health.inventory_cost_value IS
'Current inventory value calculated using stock quantity multiplied by cost price.';

COMMENT ON COLUMN gold.inventory_health.inventory_retail_value IS
'Potential retail value of current inventory using the current sale price.';

COMMENT ON COLUMN gold.inventory_health.inventory_potential_profit IS
'Estimated gross profit if all current inventory is sold at the current sale price.';

COMMENT ON COLUMN gold.inventory_health.stock_to_sales_ratio IS
'Ratio between current stock and observed units sold.';

COMMENT ON COLUMN gold.inventory_health.inventory_health_status IS
'Classification of current inventory health based on stock and observed demand.';

COMMENT ON COLUMN gold.inventory_health.replenishment_priority IS
'Recommended operational priority for inventory replenishment or demand review.';

COMMENT ON COLUMN gold.inventory_health.inventory_business_priority IS
'Business priority assigned to inventory based on demand and stock conditions.';