-- =========================================================
-- TABLE: bronze.addresses
-- DESCRIPTION:
-- Stores user addresses.
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.addresses (

    -- Primary Key
    address_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Foreign Key
    user_id BIGINT NOT NULL,

    -- Address Information
    address_name VARCHAR(100) NOT NULL,
    address_type VARCHAR(50) NOT NULL,
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,

    -- Audit Information
    created_at TIMESTAMP WITH TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP WITH TIME ZONE,

    deleted_at TIMESTAMP WITH TIME ZONE,

    -- Pipeline Metadata
    ingestion_timestamp TIMESTAMP WITH TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    source_system VARCHAR(100) NOT NULL,

    batch_id VARCHAR(100),

    record_hash CHAR(64),

    -- Constraints
    CONSTRAINT fk_addresses_user
        FOREIGN KEY (user_id)
        REFERENCES bronze.users(user_id)

);