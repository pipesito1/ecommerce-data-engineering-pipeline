-- =========================================================
-- TABLE: bronze.shipments
-- DESCRIPTION:
-- Seed data for customer shipments.
-- =========================================================

INSERT INTO bronze.shipments
(
    order_id,
    shipping_address_id,
    carrier,
    service_level,
    tracking_number,
    shipment_status,
    package_count,
    shipping_cost,
    shipped_at,
    estimated_delivery_at,
    delivered_at,
    cancelled_at,
    created_at,
    updated_at,
    source_system,
    batch_id,
    record_hash
)
VALUES

-- =========================================================
-- Shipment for Order 1
-- =========================================================

(
    2,
    3,
    'DHL',
    'Express',
    'DHL-COL-000001',
    'DELIVERED',
    1,
    25000.00,
    CURRENT_TIMESTAMP - INTERVAL '9 days',
    CURRENT_TIMESTAMP - INTERVAL '7 days',
    CURRENT_TIMESTAMP - INTERVAL '6 days',
    NULL,
    CURRENT_TIMESTAMP - INTERVAL '10 days',
    CURRENT_TIMESTAMP - INTERVAL '6 days',
    'ecommerce_app',
    'BATCH_20260731_013',
    repeat('3',64)
),

-- =========================================================
-- Shipment for Order 2
-- =========================================================

(
    3,
    7,
    'FedEx',
    'Standard',
    'FDX-USA-000002',
    'IN_TRANSIT',
    1,
    18000.00,
    CURRENT_TIMESTAMP - INTERVAL '1 day',
    CURRENT_TIMESTAMP + INTERVAL '3 days',
    NULL,
    NULL,
    CURRENT_TIMESTAMP - INTERVAL '2 days',
    CURRENT_TIMESTAMP - INTERVAL '1 day',
    'ecommerce_app',
    'BATCH_20260805_013',
    repeat('4',64)
);