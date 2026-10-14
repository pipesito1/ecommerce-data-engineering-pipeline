-- =========================================================
-- TABLE: bronze.products
-- DESCRIPTION:
-- Stores product master data from source systems.
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.products (

    -- =====================================================
    -- Primary Key
    -- =====================================================

    product_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- =====================================================
    -- Foreign Keys
    -- =====================================================

    category_id BIGINT NOT NULL,

    brand_id BIGINT NOT NULL,

    supplier_id BIGINT NOT NULL,

    -- =====================================================
    -- Product Information
    -- =====================================================

    sku VARCHAR(100) NOT NULL,

    barcode VARCHAR(100),

    slug VARCHAR(200) NOT NULL,

    product_name VARCHAR(255) NOT NULL,

    product_description TEXT,

    -- =====================================================
    -- Pricing
    -- =====================================================

    cost_price DECIMAL(12,2),

    sale_price DECIMAL(12,2),

    currency VARCHAR(10),

    tax_rate DECIMAL(5,2),

    discount_start TIMESTAMP WITH TIME ZONE,

    discount_end TIMESTAMP WITH TIME ZONE,

    -- =====================================================
    -- Inventory
    -- =====================================================

    stock_quantity INTEGER DEFAULT 0,

    low_stock_threshold INTEGER DEFAULT 5,

    backorder_allowed BOOLEAN DEFAULT FALSE,

    -- =====================================================
    -- Logistics
    -- =====================================================

    weight DECIMAL(10,2),

    height DECIMAL(10,2),

    width DECIMAL(10,2),

    length DECIMAL(10,2),

    is_shippable BOOLEAN DEFAULT TRUE,

    requires_refrigeration BOOLEAN DEFAULT FALSE,

    -- =====================================================
    -- Product Status
    -- =====================================================

    is_active BOOLEAN DEFAULT TRUE,

    is_featured BOOLEAN DEFAULT FALSE,

    -- =====================================================
    -- Reviews / Ratings
    -- =====================================================

    average_rating DECIMAL(3,2) DEFAULT 0,

    reviews_count INTEGER DEFAULT 0,

    -- =====================================================
    -- Media
    -- =====================================================

    main_image_url TEXT,

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
    -- Foreign Key Constraints
    -- =====================================================

    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES bronze.categories(category_id),

    CONSTRAINT fk_products_brand
        FOREIGN KEY (brand_id)
        REFERENCES bronze.brands(brand_id),

    CONSTRAINT fk_products_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES bronze.suppliers(supplier_id),

    -- =====================================================
    -- Unique Constraints
    -- =====================================================

    CONSTRAINT uq_products_sku
        UNIQUE (sku),

    CONSTRAINT uq_products_slug
        UNIQUE (slug),

    -- =====================================================
    -- Data Quality Constraints
    -- =====================================================

    CONSTRAINT chk_products_cost_price
        CHECK (cost_price IS NULL OR cost_price >= 0),

    CONSTRAINT chk_products_sale_price
        CHECK (sale_price IS NULL OR sale_price >= 0),

    CONSTRAINT chk_products_stock
        CHECK (stock_quantity >= 0),

    CONSTRAINT chk_products_low_stock
        CHECK (low_stock_threshold >= 0),

    CONSTRAINT chk_products_rating
        CHECK (average_rating BETWEEN 0 AND 5),

    CONSTRAINT chk_products_reviews
        CHECK (reviews_count >= 0)

);