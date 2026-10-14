-- =========================================================
-- SHIPMENTS
-- =========================================================

CREATE TABLE IF NOT EXISTS bronze.shipments (

    
    -- Primary Key
    shipment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,


    -- Foreign Keys
    order_id BIGINT NOT NULL,
    shipping_address_id BIGINT NOT NULL,

    -- Business Information
    carrier VARCHAR(100) NOT NULL,
    service_level VARCHAR(50),
    tracking_number VARCHAR(150),
    shipment_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    package_count INTEGER NOT NULL DEFAULT 1,
    shipping_cost DECIMAL(12,2) NOT NULL DEFAULT 0,

    -- Dates
    shipped_at TIMESTAMP WITH TIME ZONE,
    estimated_delivery_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,

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
    CONSTRAINT fk_shipments_order
        FOREIGN KEY (order_id)
        REFERENCES bronze.orders(order_id),

    CONSTRAINT fk_shipments_address
        FOREIGN KEY (shipping_address_id)
        REFERENCES bronze.addresses(address_id),

    CONSTRAINT uq_tracking_number
        UNIQUE (tracking_number),

    CONSTRAINT chk_shipment_status
        CHECK (
            shipment_status IN (
                'PENDING',
                'PROCESSING',
                'SHIPPED',
                'IN_TRANSIT',
                'OUT_FOR_DELIVERY',
                'DELIVERED',
                'FAILED',
                'CANCELLED',
                'RETURNED'
            )
        ),

    CONSTRAINT chk_package_count
        CHECK (package_count > 0),

    CONSTRAINT chk_shipping_cost
        CHECK (shipping_cost >= 0)

);