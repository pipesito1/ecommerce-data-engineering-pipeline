-- ============================================================
-- SILVER LAYER
-- 004_events.sql
-- Cleaned and enriched customer events
-- ============================================================

DROP TABLE IF EXISTS silver.events;

CREATE TABLE silver.events AS
SELECT
    e.event_id,
    e.user_id,
    e.product_id,
    e.session_id,

    -- Event information
    UPPER(TRIM(e.event_type)) AS event_type,
    e.event_timestamp,

    -- Web context
    e.page_url,
    LOWER(TRIM(e.device_type)) AS device_type,
    LOWER(TRIM(e.operating_system)) AS operating_system,
    LOWER(TRIM(e.browser)) AS browser,

    -- Geographic information
    INITCAP(TRIM(e.country)) AS country,
    INITCAP(TRIM(e.city)) AS city,

    -- Technical information
    e.ip_address,
    e.event_source,
    e.event_version,
    e.event_payload,

    -- Derived date/time attributes
    e.event_timestamp::date AS event_date,
    EXTRACT(HOUR FROM e.event_timestamp)::integer AS event_hour,
    EXTRACT(DOW FROM e.event_timestamp)::integer AS day_of_week,

    CASE
        WHEN EXTRACT(DOW FROM e.event_timestamp) IN (0, 6)
            THEN TRUE
        ELSE FALSE
    END AS is_weekend,

    -- Funnel classification
    CASE
        WHEN UPPER(TRIM(e.event_type)) = 'LOGIN'
            THEN 'ENGAGEMENT'

        WHEN UPPER(TRIM(e.event_type)) IN (
            'VIEW_PRODUCT',
            'SEARCH',
            'CATEGORY_VIEW'
        )
            THEN 'DISCOVERY'

        WHEN UPPER(TRIM(e.event_type)) IN (
            'ADD_TO_CART',
            'REMOVE_FROM_CART'
        )
            THEN 'CART'

        WHEN UPPER(TRIM(e.event_type)) IN (
            'CHECKOUT_STARTED',
            'PAYMENT_STARTED'
        )
            THEN 'CHECKOUT'

        WHEN UPPER(TRIM(e.event_type)) = 'PURCHASE'
            THEN 'CONVERSION'

        ELSE 'OTHER'
    END AS funnel_stage,

    -- Useful flags for analytics
    CASE
        WHEN UPPER(TRIM(e.event_type)) = 'VIEW_PRODUCT'
            THEN TRUE
        ELSE FALSE
    END AS is_product_view,

    CASE
        WHEN UPPER(TRIM(e.event_type)) = 'ADD_TO_CART'
            THEN TRUE
        ELSE FALSE
    END AS is_cart_add,

    CASE
        WHEN UPPER(TRIM(e.event_type)) = 'CHECKOUT_STARTED'
            THEN TRUE
        ELSE FALSE
    END AS is_checkout_started,

    CASE
        WHEN UPPER(TRIM(e.event_type)) = 'PAYMENT_STARTED'
            THEN TRUE
        ELSE FALSE
    END AS is_payment_started,

    CASE
        WHEN UPPER(TRIM(e.event_type)) = 'PURCHASE'
            THEN TRUE
        ELSE FALSE
    END AS is_purchase,

    -- Metadata
    e.created_at,
    e.updated_at,
    e.deleted_at,
    e.ingestion_timestamp,
    e.source_system,
    e.batch_id,
    e.record_hash

FROM bronze.events e

WHERE e.deleted_at IS NULL;


-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_silver_events_user
    ON silver.events(user_id);

CREATE INDEX idx_silver_events_session
    ON silver.events(session_id);

CREATE INDEX idx_silver_events_product
    ON silver.events(product_id);

CREATE INDEX idx_silver_events_timestamp
    ON silver.events(event_timestamp);

CREATE INDEX idx_silver_events_type
    ON silver.events(event_type);

CREATE INDEX idx_silver_events_date
    ON silver.events(event_date);


-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE silver.events IS
'Cleaned and enriched customer behavioral events used for funnel, conversion, retention and abandonment analysis.';

COMMENT ON COLUMN silver.events.funnel_stage IS
'Business funnel classification: ENGAGEMENT, DISCOVERY, CART, CHECKOUT, CONVERSION or OTHER.';

COMMENT ON COLUMN silver.events.is_purchase IS
'Flag identifying purchase/conversion events.';