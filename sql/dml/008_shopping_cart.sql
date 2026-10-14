-- =========================================================
-- TABLE: bronze.shopping_cart
-- Seed Data
-- =========================================================

INSERT INTO bronze.shopping_cart
(
    user_id,
    cart_status,
    created_at,
    updated_at,
    source_system,
    batch_id,
    record_hash
)
VALUES

(
    1,
    'ACTIVE',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    'ecommerce_app',
    'BATCH_20260731_008',
    repeat('a',64)
),

(
    2,
    'ACTIVE',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    'ecommerce_app',
    'BATCH_20260731_008',
    repeat('b',64)
),

(
    3,
    'CHECKED_OUT',
    CURRENT_TIMESTAMP - INTERVAL '3 days',
    CURRENT_TIMESTAMP - INTERVAL '2 days',
    'ecommerce_app',
    'BATCH_20260731_008',
    repeat('c',64)
),

(
    4,
    'ABANDONED',
    CURRENT_TIMESTAMP - INTERVAL '7 days',
    CURRENT_TIMESTAMP - INTERVAL '6 days',
    'ecommerce_app',
    'BATCH_20260731_008',
    repeat('d',64)
),

(
    5,
    'ACTIVE',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    'ecommerce_app',
    'BATCH_20260731_008',
    repeat('e',64)
),

(
    6,
    'CHECKED_OUT',
    CURRENT_TIMESTAMP - INTERVAL '1 day',
    CURRENT_TIMESTAMP,
    'ecommerce_app',
    'BATCH_20260731_008',
    repeat('f',64)
),

(
    7,
    'ACTIVE',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    'ecommerce_app',
    'BATCH_20260731_008',
    repeat('g',64)
),

(
    8,
    'EXPIRED',
    CURRENT_TIMESTAMP - INTERVAL '30 days',
    CURRENT_TIMESTAMP - INTERVAL '25 days',
    'ecommerce_app',
    'BATCH_20260731_008',
    repeat('h',64)
),

(
    9,
    'ACTIVE',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    'ecommerce_app',
    'BATCH_20260731_008',
    repeat('i',64)
),

(
    10,
    'ACTIVE',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    'ecommerce_app',
    'BATCH_20260731_008',
    repeat('j',64)
);