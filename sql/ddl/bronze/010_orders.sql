-- =========================================================
-- TABLE: bronze.orders
-- DESCRIPTION:
-- Stores customer orders from source systems.
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.orders (

    -- =====================================================
    -- Primary Key
    -- =====================================================

    order_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- =====================================================
    -- Business Identifier
    -- =====================================================

    order_number VARCHAR(50) NOT NULL UNIQUE,

    -- =====================================================
    -- Foreign Keys
    -- =====================================================

    user_id BIGINT NOT NULL,

    shipping_address_id BIGINT NOT NULL,

    billing_address_id BIGINT NOT NULL,

    -- =====================================================
    -- Business Information
    -- =====================================================

    order_status VARCHAR(30)
        NOT NULL DEFAULT 'PENDING',

    payment_status VARCHAR(30)
        NOT NULL DEFAULT 'PENDING',

    currency VARCHAR(10) NOT NULL,

    subtotal DECIMAL(12,2) NOT NULL,

    tax_amount DECIMAL(12,2)
        NOT NULL DEFAULT 0,

    shipping_cost DECIMAL(12,2)
        NOT NULL DEFAULT 0,

    discount_amount DECIMAL(12,2)
        NOT NULL DEFAULT 0,

    total_amount DECIMAL(12,2) NOT NULL,

    -- =====================================================
    -- Dates
    -- =====================================================

    order_date TIMESTAMP WITH TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    confirmed_at TIMESTAMP WITH TIME ZONE,

    completed_at TIMESTAMP WITH TIME ZONE,

    cancelled_at TIMESTAMP WITH TIME ZONE,

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

    CONSTRAINT fk_orders_user
        FOREIGN KEY (user_id)
        REFERENCES bronze.users(user_id),

    CONSTRAINT fk_orders_shipping_address
        FOREIGN KEY (shipping_address_id)
        REFERENCES bronze.addresses(address_id),

    CONSTRAINT fk_orders_billing_address
        FOREIGN KEY (billing_address_id)
        REFERENCES bronze.addresses(address_id),

    -- =====================================================
    -- Status Constraints
    -- =====================================================

    CONSTRAINT chk_order_status
        CHECK (
            order_status IN (
                'PENDING',
                'CONFIRMED',
                'PROCESSING',
                'SHIPPED',
                'DELIVERED',
                'CANCELLED',
                'REFUNDED'
            )
        ),

    CONSTRAINT chk_payment_status
        CHECK (
            payment_status IN (
                'PENDING',
                'AUTHORIZED',
                'PAID',
                'FAILED',
                'REFUNDED',
                'PARTIALLY_REFUNDED'
            )
        ),

    -- =====================================================
    -- Financial Constraints
    -- =====================================================

    CONSTRAINT chk_subtotal
        CHECK (subtotal >= 0),

    CONSTRAINT chk_tax
        CHECK (tax_amount >= 0),

    CONSTRAINT chk_shipping
        CHECK (shipping_cost >= 0),

    CONSTRAINT chk_discount
        CHECK (discount_amount >= 0),

    CONSTRAINT chk_total
        CHECK (total_amount >= 0),

    CONSTRAINT chk_discount_not_greater_than_subtotal
        CHECK (discount_amount <= subtotal),

    CONSTRAINT chk_total_calculation
        CHECK (
            total_amount =
            subtotal
            + tax_amount
            + shipping_cost
            - discount_amount
        )

);