-- =========================================================
-- TABLE: bronze.shopping_cart
-- DESCRIPTION:
-- Stores shopping cart information associated with users.
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.shopping_cart (

    -- =====================================================
    -- Primary Key
    -- =====================================================

    cart_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- =====================================================
    -- Foreign Key
    -- =====================================================

    user_id BIGINT NOT NULL,

    -- =====================================================
    -- Business Information
    -- =====================================================

    cart_status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',

    expires_at TIMESTAMP WITH TIME ZONE,

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

    CONSTRAINT fk_cart_user
        FOREIGN KEY (user_id)
        REFERENCES bronze.users(user_id),

    CONSTRAINT chk_cart_status
        CHECK (
            cart_status IN (
                'ACTIVE',
                'ABANDONED',
                'CHECKED_OUT',
                'EXPIRED'
            )
        )

);