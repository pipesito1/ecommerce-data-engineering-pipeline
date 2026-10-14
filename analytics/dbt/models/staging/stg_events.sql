WITH source AS (

    SELECT *
    FROM {{ source('silver', 'events') }}

)

SELECT
    event_id,
    user_id,
    product_id,
    session_id,
    event_type,
    event_timestamp,
    page_url,
    device_type,
    operating_system,
    browser,
    country,
    city,
    ip_address,
    event_source,
    event_version,
    event_payload,
    created_at,
    updated_at,
    deleted_at,
    ingestion_timestamp,
    source_system,
    batch_id,
    record_hash,
    lake_ingestion_timestamp,
    silver_processed_at,
    postgres_load_timestamp
FROM source