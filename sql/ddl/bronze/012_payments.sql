-- =========================================================
-- PAYMENTS
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.payments (

    -- Primary Key

    payment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Foreign Keys

    order_id BIGINT NOT NULL,

    -- Business Information

    payment_method VARCHAR(50) NOT NULL,
    payment_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    transaction_id VARCHAR(150) NOT NULL,
    provider VARCHAR(100),
    provider_reference VARCHAR(150),

    -- Dates

    payment_date TIMESTAMP WITH TIME ZONE,
    authorized_at TIMESTAMP WITH TIME ZONE,
    paid_at TIMESTAMP WITH TIME ZONE,
    failed_at TIMESTAMP WITH TIME ZONE,
    refunded_at TIMESTAMP WITH TIME ZONE,

    -- Audit Information

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,

    -- Pipeline Metadata

    ingestion_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source_system VARCHAR(100) NOT NULL,
    batch_id VARCHAR(100),
    record_hash CHAR(64),
    
    -- Constraints

    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES bronze.orders(order_id),

    CONSTRAINT uq_payment_transaction
        UNIQUE (transaction_id),

    CONSTRAINT chk_payment_amount
        CHECK (amount >= 0),

    CONSTRAINT chk_payment_status
        CHECK (
            payment_status IN (
                'PENDING',
                'AUTHORIZED',
                'PAID',
                'FAILED',
                'REFUNDED',
                'PARTIALLY_REFUNDED'
            )
        )

);