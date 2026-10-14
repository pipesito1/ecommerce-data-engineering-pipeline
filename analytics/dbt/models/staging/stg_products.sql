WITH source AS (

    SELECT *
    FROM {{ source('silver', 'products') }}

)

SELECT
    product_id,
    category_id,
    brand_id,
    supplier_id,
    sku,
    barcode,
    slug,
    product_name,
    product_description,
    cost_price,
    sale_price,
    currency,
    tax_rate,
    discount_start,
    discount_end,
    stock_quantity,
    low_stock_threshold,
    backorder_allowed,
    weight,
    height,
    width,
    is_shippable,
    requires_refrigeration,
    is_active,
    is_featured,
    average_rating,
    reviews_count,
    main_image_url,
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