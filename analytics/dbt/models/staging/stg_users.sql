WITH source AS (

    SELECT *
    FROM {{ source('silver', 'users') }}

),

renamed AS (

    SELECT
        user_id,
        username,
        email,
        password_hash,
        first_name,
        last_name,
        phone_number,
        date_of_birth,
        gender,
        role,
        is_verified,
        preferred_language,
        country,
        currency,
        marketing_opt_in,
        created_at,
        updated_at,
        deleted_at,
        first_access,
        last_login,
        ingestion_timestamp,
        source_system,
        batch_id,
        record_hash,
        lake_ingestion_timestamp,
        silver_processed_at,
        postgres_load_timestamp

    FROM source

)

SELECT *
FROM renamed