-- =========================================================
-- TABLE: bronze.order_items
-- DESCRIPTION:
-- Seed data for customer order line items.
-- =========================================================

INSERT INTO bronze.order_items
(
    order_id,
    variant_id,
    quantity,
    unit_price,
    discount_amount,
    created_at,
    updated_at,
    source_system,
    batch_id,
    record_hash
)
VALUES

-- =========================================================
-- ORDER 1
-- ORD-2026-000001
-- order_id = 2
-- =========================================================

(
    2,
    4,
    1,
    1799000.00,
    50000.00,
    CURRENT_TIMESTAMP - INTERVAL '10 days',
    CURRENT_TIMESTAMP - INTERVAL '6 days',
    'ecommerce_app',
    'BATCH_20260731_011',
    repeat('c',64)
),

(
    2,
    19,
    1,
    449900.00,
    0.00,
    CURRENT_TIMESTAMP - INTERVAL '10 days',
    CURRENT_TIMESTAMP - INTERVAL '6 days',
    'ecommerce_app',
    'BATCH_20260731_011',
    repeat('d',64)
),

-- =========================================================
-- ORDER 2
-- ORD-2026-000002
-- order_id = 3
-- =========================================================

(
    3,
    27,
    1,
    499900.00,
    50000.00,
    CURRENT_TIMESTAMP - INTERVAL '2 days',
    CURRENT_TIMESTAMP - INTERVAL '1 day',
    'ecommerce_app',
    'BATCH_20260731_011',
    repeat('e',64)
),

(
    3,
    29,
    2,
    129900.00,
    0.00,
    CURRENT_TIMESTAMP - INTERVAL '2 days',
    CURRENT_TIMESTAMP - INTERVAL '1 day',
    'ecommerce_app',
    'BATCH_20260731_011',
    repeat('f',64)
);