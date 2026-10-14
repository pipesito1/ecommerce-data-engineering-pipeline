WITH source AS (

    SELECT *
    FROM {{ source('silver', 'reviews') }}

)

SELECT
    review_id,
    user_id,
    product_id,
    rating,
    review_title,
    review_text,
    is_verified_purchase,
    is_approved,
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