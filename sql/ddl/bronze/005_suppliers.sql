-- =========================================================
-- TABLE: bronze.suppliers
-- DESCRIPTION:
-- Stores supplier information from the source system.
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.suppliers (

    -- Primary Key
    supplier_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Supplier Information
    supplier_name VARCHAR(150) NOT NULL,
    contact_name VARCHAR(150),
    email VARCHAR(255),
    phone_number VARCHAR(30),
    website VARCHAR(255),
    country VARCHAR(100),

    -- Business Information
    tax_identifier VARCHAR(50),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    -- Audit Information
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,

    -- Pipeline Metadata
    ingestion_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source_system VARCHAR(100) NOT NULL,
    batch_id VARCHAR(100),
    record_hash CHAR(64),

    CONSTRAINT uq_suppliers_email UNIQUE (email)

);