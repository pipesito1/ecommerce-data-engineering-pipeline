-- =========================================================
-- BRONZE - CATEGORIES
-- =========================================================

-- =========================================================
-- MAIN CATEGORIES
-- =========================================================

INSERT INTO bronze.categories (
    category_name,
    category_slug,
    category_description,
    parent_category_id,
    is_active,
    display_order,
    source_system,
    batch_id,
    record_hash
)
VALUES
(
    'Electronics',
    'electronics',
    'Electronic devices and accessories',
    NULL,
    TRUE,
    1,
    'ecommerce_app',
    'BATCH_20260731_001',
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
),
(
    'Clothing',
    'clothing',
    'Clothing and fashion products',
    NULL,
    TRUE,
    2,
    'ecommerce_app',
    'BATCH_20260731_001',
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
),
(
    'Home & Kitchen',
    'home-kitchen',
    'Products for home and kitchen',
    NULL,
    TRUE,
    3,
    'ecommerce_app',
    'BATCH_20260731_001',
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
),
(
    'Sports',
    'sports',
    'Sports and fitness products',
    NULL,
    TRUE,
    4,
    'ecommerce_app',
    'BATCH_20260731_001',
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd'
);

-- =========================================================
-- SUBCATEGORIES
-- =========================================================

INSERT INTO bronze.categories (
    category_name,
    category_slug,
    category_description,
    parent_category_id,
    is_active,
    display_order,
    source_system,
    batch_id,
    record_hash
)
VALUES
(
    'Smartphones',
    'smartphones',
    'Mobile phones and smartphones',
    (SELECT category_id
     FROM bronze.categories
     WHERE category_slug = 'electronics'),
    TRUE,
    1,
    'ecommerce_app',
    'BATCH_20260731_001',
    '1111111111111111111111111111111111111111111111111111111111111111'
),
(
    'Laptops',
    'laptops',
    'Laptops and portable computers',
    (SELECT category_id
     FROM bronze.categories
     WHERE category_slug = 'electronics'),
    TRUE,
    2,
    'ecommerce_app',
    'BATCH_20260731_001',
    '2222222222222222222222222222222222222222222222222222222222222222'
),
(
    'T-Shirts',
    't-shirts',
    'T-shirts and casual tops',
    (SELECT category_id
     FROM bronze.categories
     WHERE category_slug = 'clothing'),
    TRUE,
    1,
    'ecommerce_app',
    'BATCH_20260731_001',
    '3333333333333333333333333333333333333333333333333333333333333333'
),
(
    'Shoes',
    'shoes',
    'Footwear and shoes',
    (SELECT category_id
     FROM bronze.categories
     WHERE category_slug = 'clothing'),
    TRUE,
    2,
    'ecommerce_app',
    'BATCH_20260731_001',
    '4444444444444444444444444444444444444444444444444444444444444444'
),
(
    'Kitchen Appliances',
    'kitchen-appliances',
    'Appliances and equipment for kitchens',
    (SELECT category_id
     FROM bronze.categories
     WHERE category_slug = 'home-kitchen'),
    TRUE,
    1,
    'ecommerce_app',
    'BATCH_20260731_001',
    '5555555555555555555555555555555555555555555555555555555555555555'
),
(
    'Furniture',
    'furniture',
    'Furniture for home and office',
    (SELECT category_id
     FROM bronze.categories
     WHERE category_slug = 'home-kitchen'),
    TRUE,
    2,
    'ecommerce_app',
    'BATCH_20260731_001',
    '6666666666666666666666666666666666666666666666666666666666666666'
),
(
    'Fitness',
    'fitness',
    'Fitness and workout equipment',
    (SELECT category_id
     FROM bronze.categories
     WHERE category_slug = 'sports'),
    TRUE,
    1,
    'ecommerce_app',
    'BATCH_20260731_001',
    '7777777777777777777777777777777777777777777777777777777777777777'
),
(
    'Outdoor',
    'outdoor',
    'Outdoor and recreational equipment',
    (SELECT category_id
     FROM bronze.categories
     WHERE category_slug = 'sports'),
    TRUE,
    2,
    'ecommerce_app',
    'BATCH_20260731_001',
    '8888888888888888888888888888888888888888888888888888888888888888'
);