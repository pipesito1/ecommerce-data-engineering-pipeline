-- =========================================================
-- BRONZE - ADDRESSES
-- =========================================================

INSERT INTO bronze.addresses (
    user_id,
    address_name,
    address_type,
    address_line1,
    address_line2,
    city,
    state,
    postal_code,
    country,
    is_default,
    source_system,
    batch_id,
    record_hash
)
VALUES

-- User 1 - Felipe
(
    1,
    'Casa',
    'HOME',
    'Carrera 8 #13-50',
    NULL,
    'Ibague',
    'Tolima',
    '730001',
    'Colombia',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
),

-- User 2 - Laura
(
    2,
    'Casa',
    'HOME',
    'Carrera 15 #45-20',
    'Apartamento 302',
    'Bogota',
    'Cundinamarca',
    '110001',
    'Colombia',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
),

-- User 3 - Carlos
(
    3,
    'Casa',
    'HOME',
    'Calle 72 #10-15',
    NULL,
    'Medellin',
    'Antioquia',
    '050001',
    'Colombia',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
),

-- User 4 - Sofia
(
    4,
    'Casa',
    'HOME',
    'Calle Gran Via 45',
    'Piso 3',
    'Madrid',
    'Madrid',
    '28013',
    'Spain',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd'
),

-- User 5 - Andrei
(
    5,
    'Casa',
    'HOME',
    'Strada Victoriei 25',
    'Apartment 4',
    'Bucharest',
    'Bucharest',
    '010061',
    'Romania',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'
),

-- User 6 - Anna
(
    6,
    'Casa',
    'HOME',
    'ul. Marszalkowska 10',
    'Apartment 12',
    'Warsaw',
    'Masovian',
    '00-001',
    'Poland',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'
),

-- User 7 - David
(
    7,
    'Home',
    'HOME',
    '123 Main Street',
    'Apt 5B',
    'New York',
    'New York',
    '10001',
    'United States',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    '1111111111111111111111111111111111111111111111111111111111111111'
),

-- User 8 - Emma
(
    8,
    'Home',
    'HOME',
    '456 Oak Avenue',
    NULL,
    'Chicago',
    'Illinois',
    '60601',
    'United States',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    '2222222222222222222222222222222222222222222222222222222222222222'
),

-- User 9 - Marco
(
    9,
    'Casa',
    'HOME',
    'Via Roma 120',
    'Scala B',
    'Rome',
    'Lazio',
    '00100',
    'Italy',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    '3333333333333333333333333333333333333333333333333333333333333333'
),

-- User 10 - Olena
(
    10,
    'Home',
    'HOME',
    'Shevchenka Street 15',
    'Apartment 8',
    'Lviv',
    'Lviv Oblast',
    '79000',
    'Ukraine',
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_001',
    '4444444444444444444444444444444444444444444444444444444444444444'
),

-- User 1 - segunda dirección
(
    1,
    'Trabajo',
    'WORK',
    'Calle 10 #5-30',
    'Oficina 201',
    'Ibague',
    'Tolima',
    '730002',
    'Colombia',
    FALSE,
    'ecommerce_app',
    'BATCH_20260731_001',
    '5555555555555555555555555555555555555555555555555555555555555555'
),

-- User 2 - segunda dirección
(
    2,
    'Trabajo',
    'WORK',
    'Carrera 7 #80-40',
    'Oficina 501',
    'Bogota',
    'Cundinamarca',
    '110221',
    'Colombia',
    FALSE,
    'ecommerce_app',
    'BATCH_20260731_001',
    '6666666666666666666666666666666666666666666666666666666666666666'
);