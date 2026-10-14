-- =========================================================
-- BRONZE - SUPPLIERS
-- =========================================================

INSERT INTO bronze.suppliers (
    supplier_name,
    contact_name,
    email,
    phone_number,
    website,
    country,
    tax_identifier,
    is_active,
    source_system,
    batch_id,
    record_hash
)
VALUES
(
    'Global Tech Distribution',
    'Michael Johnson',
    'contact@globaltech.example.com',
    '+1-212-555-0101',
    'https://globaltech.example.com',
    'United States',
    'US-TAX-10001',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
),
(
    'Euro Electronics Supply',
    'Hans Mueller',
    'sales@euroelectronics.example.com',
    '+49-30-555-0102',
    'https://euroelectronics.example.com',
    'Germany',
    'DE-TAX-10002',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
),
(
    'Moda Europa Distribution',
    'Carlos Fernandez',
    'contact@modaeuropa.example.com',
    '+34-91-555-0103',
    'https://modaeuropa.example.com',
    'Spain',
    'ES-TAX-10003',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
),
(
    'Italian Footwear Supply',
    'Marco Bianchi',
    'sales@italianfootwear.example.com',
    '+39-06-555-0104',
    'https://italianfootwear.example.com',
    'Italy',
    'IT-TAX-10004',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd'
),
(
    'Central Europe Home Supply',
    'Anna Nowak',
    'contact@cehome.example.com',
    '+48-22-555-0105',
    'https://cehome.example.com',
    'Poland',
    'PL-TAX-10005',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'
),
(
    'French Kitchen Distribution',
    'Pierre Martin',
    'sales@frenchkitchen.example.com',
    '+33-1-555-0106',
    'https://frenchkitchen.example.com',
    'France',
    'FR-TAX-10006',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'
),
(
    'North America Fitness Supply',
    'Daniel Brown',
    'contact@nafitness.example.com',
    '+1-416-555-0107',
    'https://nafitness.example.com',
    'Canada',
    'CA-TAX-10007',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    '1111111111111111111111111111111111111111111111111111111111111111'
),
(
    'Alpine Outdoor Distribution',
    'Lukas Steiner',
    'sales@alpineoutdoor.example.com',
    '+41-44-555-0108',
    'https://alpineoutdoor.example.com',
    'Switzerland',
    'CH-TAX-10008',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    '2222222222222222222222222222222222222222222222222222222222222222'
);