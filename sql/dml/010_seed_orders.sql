-- =========================================================
-- TABLE: bronze.orders
-- Seed Data
-- =========================================================

INSERT INTO bronze.orders
(
    order_number,
    user_id,
    shipping_address_id,
    billing_address_id,
    order_status,
    payment_status,
    currency,
    subtotal,
    tax_amount,
    shipping_cost,
    discount_amount,
    total_amount,
    order_date,
    confirmed_at,
    completed_at,
    created_at,
    updated_at,
    source_system,
    batch_id,
    record_hash
)
VALUES

-- =========================================================
-- ORDER 1
-- User 3
-- =========================================================

(
    'ORD-2026-000001',
    3,
    3,
    3,
    'DELIVERED',
    'PAID',
    'COP',

    2198900.00,
    417791.00,
    25000.00,
    50000.00,
    2591691.00,

    CURRENT_TIMESTAMP - INTERVAL '10 days',
    CURRENT_TIMESTAMP - INTERVAL '10 days',
    CURRENT_TIMESTAMP - INTERVAL '6 days',

    CURRENT_TIMESTAMP - INTERVAL '10 days',
    CURRENT_TIMESTAMP - INTERVAL '6 days',

    'ecommerce_app',
    'BATCH_20260731_010',

    repeat('a',64)
),

-- =========================================================
-- ORDER 2
-- User 6
-- =========================================================

(
    'ORD-2026-000002',
    6,
    6,
    6,
    'SHIPPED',
    'PAID',
    'PLN',

    709700.00,
    134843.00,
    20000.00,
    50000.00,
    814543.00,

    CURRENT_TIMESTAMP - INTERVAL '2 days',
    CURRENT_TIMESTAMP - INTERVAL '2 days',
    NULL,

    CURRENT_TIMESTAMP - INTERVAL '2 days',
    CURRENT_TIMESTAMP - INTERVAL '1 day',

    'ecommerce_app',
    'BATCH_20260731_010',

    repeat('b',64)
);