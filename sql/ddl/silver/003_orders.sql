-- =========================================================
-- SILVER LAYER
-- TABLE: silver.orders
-- DESCRIPTION:
-- Cleaned and enriched customer orders from Bronze.
-- Includes customer, address and order-item information.
-- =========================================================

DROP TABLE IF EXISTS silver.orders;

CREATE TABLE silver.orders AS

WITH order_item_summary AS (

    SELECT
        oi.order_id,

        COUNT(*) AS order_item_count,

        SUM(oi.quantity) AS total_quantity,

        SUM(oi.discount_amount) AS items_discount_amount,

        SUM(oi.total_price) AS items_total_amount

    FROM bronze.order_items oi

    WHERE oi.deleted_at IS NULL

    GROUP BY oi.order_id
)

SELECT

    -- =====================================================
    -- Order Identification
    -- =====================================================

    o.order_id,

    TRIM(o.order_number) AS order_number,

    -- =====================================================
    -- Customer
    -- =====================================================

    o.user_id,

    TRIM(u.username) AS username,

    TRIM(u.email) AS email,

    TRIM(u.first_name) AS first_name,

    TRIM(u.last_name) AS last_name,

    TRIM(u.country) AS customer_country,

    TRIM(u.currency) AS customer_currency,

    -- =====================================================
    -- Shipping Address
    -- =====================================================

    o.shipping_address_id,

    TRIM(sa.city) AS shipping_city,

    TRIM(sa.country) AS shipping_country,

    -- =====================================================
    -- Billing Address
    -- =====================================================

    o.billing_address_id,

    TRIM(ba.city) AS billing_city,

    TRIM(ba.country) AS billing_country,

    -- =====================================================
    -- Order Status
    -- =====================================================

    TRIM(o.order_status) AS order_status,

    TRIM(o.payment_status) AS payment_status,

    TRIM(o.currency) AS currency,

    -- =====================================================
    -- Financial Information
    -- =====================================================

    o.subtotal,

    o.tax_amount,

    o.shipping_cost,

    o.discount_amount,

    o.total_amount,

    -- =====================================================
    -- Order Item Metrics
    -- =====================================================

    COALESCE(oi.order_item_count, 0) AS order_item_count,

    COALESCE(oi.total_quantity, 0) AS total_quantity,

    COALESCE(oi.items_discount_amount, 0) AS items_discount_amount,

    COALESCE(oi.items_total_amount, 0) AS items_total_amount,

    -- =====================================================
    -- Data Quality Validation
    -- =====================================================

    CASE
        WHEN o.total_amount =
             o.subtotal
             + o.tax_amount
             + o.shipping_cost
        THEN 'VALID'

        ELSE 'CHECK_REQUIRED'
    END AS total_calculation_status,

    -- =====================================================
    -- Dates
    -- =====================================================

    o.order_date,

    o.confirmed_at,

    o.completed_at,

    o.cancelled_at,

    o.created_at,

    o.updated_at,

    -- =====================================================
    -- Pipeline Metadata
    -- =====================================================

    o.ingestion_timestamp,

    TRIM(o.source_system) AS source_system,

    o.batch_id,

    o.record_hash

FROM bronze.orders o

-- =========================================================
-- Customer
-- =========================================================

LEFT JOIN silver.users u
    ON o.user_id = u.user_id

-- =========================================================
-- Shipping Address
-- =========================================================

LEFT JOIN bronze.addresses sa
    ON o.shipping_address_id = sa.address_id

-- =========================================================
-- Billing Address
-- =========================================================

LEFT JOIN bronze.addresses ba
    ON o.billing_address_id = ba.address_id

-- =========================================================
-- Order Items Aggregation
-- =========================================================

LEFT JOIN order_item_summary oi
    ON o.order_id = oi.order_id

-- =========================================================
-- Remove soft-deleted orders
-- =========================================================

WHERE o.deleted_at IS NULL;