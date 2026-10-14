-- =========================================================
-- TABLE: bronze.brands
-- DESCRIPTION:
-- Stores product brands from the source system.
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.brands (
    
    -- Primary Key
    brand_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Brand Information
    brand_name VARCHAR(100) NOT NULL,
    brand_slug VARCHAR(150) NOT NULL,
    brand_description TEXT,
    website VARCHAR(255),
    country VARCHAR(100),
    founded_year SMALLINT,

    -- Business Information
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    display_order INTEGER DEFAULT 0,

    -- Audit Information
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,

    -- Pipeline Metadata
    ingestion_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source_system VARCHAR(100) NOT NULL,
    batch_id VARCHAR(100),
    record_hash CHAR(64),

    -- Constraints
    CONSTRAINT uq_brands_name
        UNIQUE (brand_name),

    CONSTRAINT uq_brands_slug
        UNIQUE (brand_slug)

);