-- =========================================================
-- TABLE: bronze.order_items
-- DESCRIPTION:
-- Stores the products/variants included in customer orders.
-- Preserves the historical purchase price.
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.order_items (

    -- =====================================================
    -- Primary Key
    -- =====================================================

    order_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- =====================================================
    -- Foreign Keys
    -- =====================================================

    order_id BIGINT NOT NULL,

    variant_id BIGINT NOT NULL,

    -- =====================================================
    -- Business Information
    -- =====================================================

    quantity INTEGER NOT NULL DEFAULT 1,

    unit_price DECIMAL(12,2) NOT NULL,

    discount_amount DECIMAL(12,2)
        NOT NULL DEFAULT 0,

    total_price DECIMAL(12,2)
        GENERATED ALWAYS AS (
            (quantity * unit_price) - discount_amount
        ) STORED,

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

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES bronze.orders(order_id),

    CONSTRAINT fk_order_items_variant
        FOREIGN KEY (variant_id)
        REFERENCES bronze.product_variants(variant_id),

    -- =====================================================
    -- Business Constraints
    -- =====================================================

    CONSTRAINT chk_order_item_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_order_item_unit_price
        CHECK (unit_price >= 0),

    CONSTRAINT chk_order_item_discount
        CHECK (discount_amount >= 0),

    CONSTRAINT chk_order_item_discount_limit
        CHECK (
            discount_amount <= quantity * unit_price
        ),

    CONSTRAINT uq_order_variant
        UNIQUE (order_id, variant_id)

);