-- =========================================================
-- TABLE: bronze.cart_items
-- DESCRIPTION:
-- Stores products/variants added to shopping carts.
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.cart_items (

    -- =====================================================
    -- Primary Key
    -- =====================================================

    cart_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- =====================================================
    -- Foreign Keys
    -- =====================================================

    cart_id BIGINT NOT NULL,

    variant_id BIGINT NOT NULL,

    -- =====================================================
    -- Business Information
    -- =====================================================

    quantity INTEGER NOT NULL DEFAULT 1,

    unit_price DECIMAL(12,2) NOT NULL,

    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,

    total_price DECIMAL(12,2)
        GENERATED ALWAYS AS (
            (quantity * unit_price) - discount_amount
        ) STORED,

    -- =====================================================
    -- Audit Information
    -- =====================================================

    added_at TIMESTAMP WITH TIME ZONE
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

    CONSTRAINT fk_cart_items_cart
        FOREIGN KEY (cart_id)
        REFERENCES bronze.shopping_cart(cart_id),

    CONSTRAINT fk_cart_items_variant
        FOREIGN KEY (variant_id)
        REFERENCES bronze.product_variants(variant_id),

    CONSTRAINT chk_cart_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_unit_price
        CHECK (unit_price >= 0),

    CONSTRAINT chk_discount
        CHECK (discount_amount >= 0),

    CONSTRAINT chk_discount_not_greater_than_item_total
        CHECK (discount_amount <= quantity * unit_price),

    CONSTRAINT uq_cart_variant
        UNIQUE (cart_id, variant_id)

);