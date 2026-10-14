-- =========================================================
-- EVENTS
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.events (

    -- =========================================================
    -- Primary Key
    -- =========================================================

    event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- =========================================================
    -- Foreign Keys
    -- =========================================================

    user_id BIGINT,

    product_id BIGINT,

    -- =========================================================
    -- Event Information
    -- =========================================================

    session_id VARCHAR(150) NOT NULL,

    event_type VARCHAR(50) NOT NULL,

    event_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,

    page_url TEXT,

    -- =========================================================
    -- Device Information
    -- =========================================================

    device_type VARCHAR(50),

    operating_system VARCHAR(100),

    browser VARCHAR(100),

    -- =========================================================
    -- Location Information
    -- =========================================================

    country VARCHAR(100),

    city VARCHAR(100),

    ip_address INET,

    -- =========================================================
    -- Event Metadata
    -- =========================================================

    event_source VARCHAR(100),

    event_version VARCHAR(20),

    event_payload JSONB,

    -- =========================================================
    -- Audit Information
    -- =========================================================

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP WITH TIME ZONE,

    deleted_at TIMESTAMP WITH TIME ZONE,

    -- =========================================================
    -- Pipeline Metadata
    -- =========================================================

    ingestion_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    source_system VARCHAR(100) NOT NULL,

    batch_id VARCHAR(100),

    record_hash CHAR(64),

    -- =========================================================
    -- Constraints
    -- =========================================================

    CONSTRAINT fk_events_user
        FOREIGN KEY (user_id)
        REFERENCES bronze.users(user_id),

    CONSTRAINT fk_events_product
        FOREIGN KEY (product_id)
        REFERENCES bronze.products(product_id),

    CONSTRAINT chk_event_type
        CHECK (
            event_type IN (
                'LOGIN',
                'LOGOUT',
                'SEARCH',
                'VIEW_PRODUCT',
                'ADD_TO_CART',
                'REMOVE_FROM_CART',
                'VIEW_CART',
                'CHECKOUT_STARTED',
                'PAYMENT_STARTED',
                'PURCHASE',
                'REVIEW_CREATED'
            )
        )

);
