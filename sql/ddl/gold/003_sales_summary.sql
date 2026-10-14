-- ============================================================
-- GOLD: SALES SUMMARY
-- ============================================================
-- Grain:
--   One row per order date and currency.
--
-- Business definition of valid sale:
--   - Payment status must be PAID
--   - Order must not be cancelled
--
-- Currency is kept as part of the grain to avoid
-- aggregating monetary values from different currencies.
-- ============================================================


DROP TABLE IF EXISTS gold.sales_summary;


CREATE TABLE gold.sales_summary AS

WITH valid_orders AS (

    SELECT
        order_id,
        order_number,
        user_id,
        username,

        order_status,
        payment_status,

        currency,

        subtotal,
        tax_amount,
        shipping_cost,
        discount_amount,
        total_amount,

        order_item_count,
        total_quantity,

        items_discount_amount,
        items_total_amount,

        order_date,
        confirmed_at,
        completed_at,
        cancelled_at

    FROM silver.orders

    WHERE payment_status = 'PAID'
      AND cancelled_at IS NULL
)


SELECT

    -- ========================================================
    -- Time dimension
    -- ========================================================

    order_date::date AS sales_date,

    EXTRACT(
        YEAR FROM order_date
    )::integer AS sales_year,

    EXTRACT(
        MONTH FROM order_date
    )::integer AS sales_month,

    EXTRACT(
        DAY FROM order_date
    )::integer AS sales_day,

    EXTRACT(
        DOW FROM order_date
    )::integer AS day_of_week,

    CASE
        WHEN EXTRACT(DOW FROM order_date) IN (0, 6)
        THEN TRUE
        ELSE FALSE
    END AS is_weekend,


    -- ========================================================
    -- Currency
    -- ========================================================

    currency,


    -- ========================================================
    -- Order metrics
    -- ========================================================

    COUNT(*) AS total_orders,

    COUNT(
        DISTINCT user_id
    ) AS unique_customers,

    COUNT(
        DISTINCT order_number
    ) AS unique_order_numbers,


    -- ========================================================
    -- Quantity metrics
    -- ========================================================

    COALESCE(
        SUM(order_item_count),
        0
    ) AS total_order_items,

    COALESCE(
        SUM(total_quantity),
        0
    ) AS total_units_sold,


    -- ========================================================
    -- Revenue metrics
    -- ========================================================

    COALESCE(
        SUM(subtotal),
        0
    ) AS gross_subtotal,

    COALESCE(
        SUM(items_discount_amount),
        0
    ) AS item_discount_amount,

    COALESCE(
        SUM(discount_amount),
        0
    ) AS total_discount_amount,

    COALESCE(
        SUM(tax_amount),
        0
    ) AS total_tax_amount,

    COALESCE(
        SUM(shipping_cost),
        0
    ) AS total_shipping_cost,

    COALESCE(
        SUM(total_amount),
        0
    ) AS total_revenue,


    -- ========================================================
    -- Average metrics
    -- ========================================================

    ROUND(
        AVG(total_amount),
        2
    ) AS average_order_value,

    ROUND(
        AVG(total_quantity),
        2
    ) AS average_units_per_order,

    ROUND(
        AVG(order_item_count),
        2
    ) AS average_items_per_order,


    -- ========================================================
    -- Discount metrics
    -- ========================================================

    ROUND(
        CASE
            WHEN SUM(subtotal) > 0
            THEN
                (
                    SUM(discount_amount)
                    / SUM(subtotal)
                ) * 100
            ELSE 0
        END,
        2
    ) AS discount_rate,


    -- ========================================================
    -- Tax metrics
    -- ========================================================

    ROUND(
        CASE
            WHEN SUM(subtotal) > 0
            THEN
                (
                    SUM(tax_amount)
                    / SUM(subtotal)
                ) * 100
            ELSE 0
        END,
        2
    ) AS effective_tax_rate,


    -- ========================================================
    -- Shipping metrics
    -- ========================================================

    ROUND(
        CASE
            WHEN COUNT(*) > 0
            THEN
                SUM(shipping_cost)
                / COUNT(*)
            ELSE 0
        END,
        2
    ) AS average_shipping_cost,


    -- ========================================================
    -- Order status metrics
    -- ========================================================

    COUNT(*) FILTER (
        WHERE order_status = 'DELIVERED'
    ) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'SHIPPED'
    ) AS shipped_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'PROCESSING'
    ) AS processing_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'CONFIRMED'
    ) AS confirmed_orders,


    -- ========================================================
    -- Fulfillment rate
    -- ========================================================

    ROUND(
        CASE
            WHEN COUNT(*) > 0
            THEN
                (
                    COUNT(*) FILTER (
                        WHERE order_status = 'DELIVERED'
                    )::numeric
                    / COUNT(*)
                ) * 100
            ELSE 0
        END,
        2
    ) AS delivery_rate,


    -- ========================================================
    -- Metadata
    -- ========================================================

    CURRENT_TIMESTAMP AS gold_created_at


FROM valid_orders

GROUP BY
    order_date::date,
    EXTRACT(YEAR FROM order_date),
    EXTRACT(MONTH FROM order_date),
    EXTRACT(DAY FROM order_date),
    EXTRACT(DOW FROM order_date),
    currency;


-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_gold_sales_summary_date
ON gold.sales_summary(sales_date);


CREATE INDEX idx_gold_sales_summary_currency
ON gold.sales_summary(currency);


CREATE INDEX idx_gold_sales_summary_revenue
ON gold.sales_summary(total_revenue);


-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE gold.sales_summary IS
'Gold-level daily sales summary by currency for paid, non-cancelled orders.';


COMMENT ON COLUMN gold.sales_summary.total_revenue IS
'Total revenue from paid, non-cancelled orders.';


COMMENT ON COLUMN gold.sales_summary.average_order_value IS
'Average total order value for the sales date and currency.';


COMMENT ON COLUMN gold.sales_summary.discount_rate IS
'Percentage of gross subtotal represented by total discounts.';


COMMENT ON COLUMN gold.sales_summary.delivery_rate IS
'Percentage of valid paid orders with DELIVERED status.';


COMMENT ON COLUMN gold.sales_summary.currency IS
'Currency used for all monetary metrics in the row.';