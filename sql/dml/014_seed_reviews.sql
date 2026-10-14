-- =========================================================
-- TABLE: bronze.reviews
-- DESCRIPTION:
-- Seed data for customer product reviews.
-- =========================================================

INSERT INTO bronze.reviews
(
    user_id,
    product_id,
    rating,
    review_title,
    review_text,
    is_verified_purchase,
    is_approved,
    created_at,
    updated_at,
    source_system,
    batch_id,
    record_hash
)
VALUES

(
    3,
    1,
    5,
    'Excelente teléfono',
    'Muy rápido, excelente cámara y batería.',
    TRUE,
    TRUE,
    CURRENT_TIMESTAMP - INTERVAL '5 days',
    CURRENT_TIMESTAMP - INTERVAL '4 days',
    'ecommerce_app',
    'BATCH_20260731_014',
    repeat('5',64)
),

(
    7,
    7,
    4,
    'Muy cómodos',
    'Los zapatos son cómodos para correr largas distancias.',
    TRUE,
    TRUE,
    CURRENT_TIMESTAMP - INTERVAL '3 days',
    CURRENT_TIMESTAMP - INTERVAL '2 days',
    'ecommerce_app',
    'BATCH_20260805_014',
    repeat('6',64)
),

(
    2,
    10,
    5,
    'Excelente licuadora',
    'Potente y muy silenciosa.',
    FALSE,
    TRUE,
    CURRENT_TIMESTAMP - INTERVAL '6 days',
    CURRENT_TIMESTAMP - INTERVAL '5 days',
    'ecommerce_app',
    'BATCH_20260731_014',
    repeat('7',64)
),

(
    9,
    15,
    4,
    'Buena tienda',
    'La carpa cumplió perfectamente durante el viaje.',
    TRUE,
    TRUE,
    CURRENT_TIMESTAMP - INTERVAL '1 day',
    CURRENT_TIMESTAMP,
    'ecommerce_app',
    'BATCH_20260805_014',
    repeat('8',64)
);