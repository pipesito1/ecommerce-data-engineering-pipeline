-- =========================================================
-- TABLE: bronze.users
-- DESCRIPTION:
-- Stores raw user information ingested from operational systems.
-- This table belongs to the Bronze layer of the Medallion Architecture
-- and preserves the original business data with minimal transformations.
-- =========================================================
-- USERS
CREATE TABLE IF NOT EXISTS bronze.users (

    -- Primary Key
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Authentication
    username VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,

    -- Personal Information
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(30),
    date_of_birth DATE, 
    gender VARCHAR(20),

    -- Business Information
    role VARCHAR(50) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    preferred_language VARCHAR(10),
    country VARCHAR(100),
    currency VARCHAR(10),
    marketing_opt_in BOOLEAN DEFAULT FALSE,

    -- Audit Information
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    first_access TIMESTAMP WITH TIME ZONE,
    last_login TIMESTAMP WITH TIME ZONE,

    -- Pipeline Metadata
    ingestion_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source_system VARCHAR(100) NOT NULL,
    batch_id VARCHAR(100),
    record_hash CHAR(64)

);