-- =========================================================
-- REVIEWS
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.reviews (

    -- =========================================================
    -- Primary Key
    -- =========================================================

    review_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- =========================================================
    -- Foreign Keys
    -- =========================================================

    user_id BIGINT NOT NULL,

    product_id BIGINT NOT NULL,

    -- =========================================================
    -- Business Information
    -- =========================================================

    rating INTEGER NOT NULL,

    review_title VARCHAR(255),

    review_text TEXT,

    is_verified_purchase BOOLEAN NOT NULL DEFAULT FALSE,

    is_approved BOOLEAN NOT NULL DEFAULT TRUE,

    -- =========================================================
    -- Audit Information
    -- =========================================================

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP WITH TIME ZONE,

    deleted_at TIMESTAMP WITH TIME ZONE,

    -- =========================================================
    -- Pipeline Metadata
    -- =========================================================

    ingestion_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    source_system VARCHAR(100) NOT NULL,

    batch_id VARCHAR(100),

    record_hash CHAR(64),

    -- =========================================================
    -- Constraints
    -- =========================================================

    CONSTRAINT fk_reviews_user
        FOREIGN KEY (user_id)
        REFERENCES bronze.users(user_id),

    CONSTRAINT fk_reviews_product
        FOREIGN KEY (product_id)
        REFERENCES bronze.products(product_id),

    CONSTRAINT chk_review_rating
        CHECK (rating BETWEEN 1 AND 5),

    CONSTRAINT uq_user_product_review
        UNIQUE (user_id, product_id)

);