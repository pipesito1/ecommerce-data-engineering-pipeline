-- =========================================================
-- TABLE: bronze.categories
-- DESCRIPTION:
-- Stores product categories from the source system.
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.categories (
    
    -- Primary Key
    category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Category Information
    category_name VARCHAR(100) NOT NULL,
    category_slug VARCHAR(150) NOT NULL,
    category_description TEXT,

    -- Hierarchy
    parent_category_id BIGINT,

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
    record_hash VARCHAR(100),

    CONSTRAINT fk_categories_parent
        FOREIGN KEY (parent_category_id)
        REFERENCES bronze.categories(category_id)

); 