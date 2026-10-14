-- =====================================================
-- SILVER LAYER
-- TABLE: silver.users
-- DESCRIPTION:
-- Cleaned and standardized users from Bronze.
-- =====================================================

DROP TABLE IF EXISTS silver.users;

CREATE TABLE silver.users AS

SELECT

    user_id,

    TRIM(username)                     AS username,

    LOWER(TRIM(email))                 AS email,

    INITCAP(TRIM(first_name))          AS first_name,

    INITCAP(TRIM(last_name))           AS last_name,

    LOWER(TRIM(country))               AS country,

    UPPER(TRIM(currency))              AS currency,

    role,

    is_active,

    is_verified,

    created_at,

    updated_at,

    ingestion_timestamp,

    source_system

FROM bronze.users

WHERE

    deleted_at IS NULL
    AND is_active = TRUE;