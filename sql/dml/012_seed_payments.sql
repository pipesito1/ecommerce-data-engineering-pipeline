-- =========================================================
-- TABLE: bronze.payments
-- DESCRIPTION:
-- Seed data for customer payments.
-- =========================================================

INSERT INTO bronze.payments
(
    order_id,
    payment_method,
    payment_status,
    amount,
    currency,
    transaction_id,
    provider,
    provider_reference,
    payment_date,
    authorized_at,
    paid_at,
    failed_at,
    refunded_at,
    created_at,
    updated_at,
    source_system,
    batch_id,
    record_hash
)
VALUES

-- =========================================================
-- ORDER 1
-- =========================================================

(
    2,
    'CREDIT_CARD',
    'PAID',
    2591691.00,
    'COP',
    'TXN-20260731-000001',
    'Stripe',
    'STRIPE-000001',
    CURRENT_TIMESTAMP - INTERVAL '10 days',
    CURRENT_TIMESTAMP - INTERVAL '10 days',
    CURRENT_TIMESTAMP - INTERVAL '10 days',
    NULL,
    NULL,
    CURRENT_TIMESTAMP - INTERVAL '10 days',
    CURRENT_TIMESTAMP - INTERVAL '6 days',
    'ecommerce_app',
    'BATCH_20260731_012',
    repeat('1',64)
),

-- =========================================================
-- ORDER 2
-- =========================================================

(
    3,
    'PAYPAL',
    'AUTHORIZED',
    709700.00,
    'COP',
    'TXN-20260805-000002',
    'PayPal',
    'PAYPAL-000002',
    CURRENT_TIMESTAMP - INTERVAL '2 days',
    CURRENT_TIMESTAMP - INTERVAL '2 days',
    NULL,
    NULL,
    NULL,
    CURRENT_TIMESTAMP - INTERVAL '2 days',
    CURRENT_TIMESTAMP - INTERVAL '1 day',
    'ecommerce_app',
    'BATCH_20260805_012',
    repeat('2',64)
);