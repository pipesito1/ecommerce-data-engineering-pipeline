-- =========================================================
-- TABLE: bronze.product_variants
-- DESCRIPTION:
-- Stores product variants such as size, color and material.
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.product_variants (

    -- =====================================================
    -- Primary Key
    -- =====================================================

    variant_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- =====================================================
    -- Relationships
    -- =====================================================

    product_id BIGINT NOT NULL,

    -- =====================================================
    -- Business Information
    -- =====================================================

    sku VARCHAR(100) NOT NULL,

    barcode VARCHAR(100),

    variant_name VARCHAR(255) NOT NULL,

    color VARCHAR(50),

    size VARCHAR(50),

    material VARCHAR(100),

    -- =====================================================
    -- Pricing
    -- =====================================================

    price DECIMAL(12,2) NOT NULL,

    cost DECIMAL(12,2),

    -- =====================================================
    -- Inventory
    -- =====================================================

    stock_quantity INTEGER NOT NULL DEFAULT 0,

    -- =====================================================
    -- Logistics
    -- =====================================================

    weight DECIMAL(10,2),

    -- =====================================================
    -- Status
    -- =====================================================

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    -- =====================================================
    -- Audit Information
    -- =====================================================

    created_at TIMESTAMP WITH TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP WITH TIME ZONE,

    deleted_at TIMESTAMP WITH TIME ZONE,

    -- =====================================================
    -- Pipeline Metadata
    -- =====================================================

    ingestion_timestamp TIMESTAMP WITH TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    source_system VARCHAR(100) NOT NULL,

    batch_id VARCHAR(100),

    record_hash CHAR(64),

    -- =====================================================
    -- Constraints
    -- =====================================================

    CONSTRAINT uq_variant_sku
        UNIQUE (sku),

    CONSTRAINT fk_product_variants_product
        FOREIGN KEY (product_id)
        REFERENCES bronze.products(product_id),

    CONSTRAINT chk_variant_price
        CHECK (price >= 0),

    CONSTRAINT chk_variant_cost
        CHECK (cost IS NULL OR cost >= 0),

    CONSTRAINT chk_variant_stock
        CHECK (stock_quantity >= 0),

    CONSTRAINT chk_variant_weight
        CHECK (weight IS NULL OR weight >= 0)

);