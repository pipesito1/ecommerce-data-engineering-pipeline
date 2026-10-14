-- =========================================================
-- SILVER LAYER
-- TABLE: silver.products
-- DESCRIPTION:
-- Cleaned, standardized and enriched products from Bronze.
-- =========================================================

DROP TABLE IF EXISTS silver.products;

CREATE TABLE silver.products AS

SELECT
    -- =====================================================
    -- Product Identification
    -- =====================================================

    p.product_id,

    TRIM(p.sku) AS sku,

    TRIM(p.barcode) AS barcode,

    TRIM(p.slug) AS slug,

    TRIM(p.product_name) AS product_name,

    NULLIF(TRIM(p.product_description), '') AS product_description,

    -- =====================================================
    -- Category
    -- =====================================================

    p.category_id,

    TRIM(c.category_name) AS category_name,

    c.parent_category_id,

    -- =====================================================
    -- Brand
    -- =====================================================

    p.brand_id,

    TRIM(b.brand_name) AS brand_name,

    -- =====================================================
    -- Supplier
    -- =====================================================

    p.supplier_id,

    TRIM(s.supplier_name) AS supplier_name,

    -- =====================================================
    -- Pricing
    -- =====================================================

    p.cost_price,

    p.sale_price,

    TRIM(p.currency) AS currency,

    p.tax_rate,

    -- =====================================================
    -- Discount Period
    -- =====================================================

    p.discount_start,

    p.discount_end,

    -- =====================================================
    -- Inventory
    -- =====================================================

    p.stock_quantity,

    p.low_stock_threshold,

    p.backorder_allowed,

    -- =====================================================
    -- Physical Attributes
    -- =====================================================

    p.weight,

    p.height,

    p.width,

    p.length,

    -- =====================================================
    -- Product Flags
    -- =====================================================

    p.is_shippable,

    p.requires_refrigeration,

    p.is_active,

    p.is_featured,

    -- =====================================================
    -- Reviews / Ratings
    -- =====================================================

    p.average_rating,

    p.reviews_count,

    -- =====================================================
    -- Media
    -- =====================================================

    p.main_image_url,

    -- =====================================================
    -- Audit Information
    -- =====================================================

    p.created_at,

    p.updated_at,

    -- =====================================================
    -- Pipeline Metadata
    -- =====================================================

    p.ingestion_timestamp,

    p.source_system,

    p.batch_id,

    p.record_hash

FROM bronze.products p

LEFT JOIN bronze.categories c
    ON p.category_id = c.category_id

LEFT JOIN bronze.brands b
    ON p.brand_id = b.brand_id

LEFT JOIN bronze.suppliers s
    ON p.supplier_id = s.supplier_id

WHERE p.deleted_at IS NULL;