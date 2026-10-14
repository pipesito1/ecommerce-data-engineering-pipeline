WITH source AS (

    SELECT *
    FROM {{ source('silver', 'orders') }}

)

SELECT
    order_id,
    order_number,
    user_id,
    shipping_address_id,
    billing_address_id,
    order_status,
    payment_status,
    currency,
    subtotal,
    shipping_cost,
    discount_amount,
    total_amount,
    order_date,
    confirmed_at,
    completed_at,
    cancelled_at,
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