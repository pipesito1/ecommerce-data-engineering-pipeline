-- =========================================================
-- DML: PRODUCT VARIANTS
-- DESCRIPTION:
-- Seeds product variants for the existing products.
-- =========================================================

INSERT INTO bronze.product_variants (
    product_id,
    sku,
    barcode,
    color,
    size,
    material,
    variant_name,
    price,
    cost,
    stock_quantity,
    weight,
    is_active,
    source_system,
    batch_id,
    record_hash
)
VALUES

-- =========================================================
-- SMARTPHONES
-- Product 1: TechNova Smartphone X1
-- =========================================================

(
    1,
    'TECH-SMART-001-BLK',
    '7701000000011',
    'Black',
    '128GB',
    'Aluminum',
    'Smartphone X1 - Black 128GB',
    1199000.00,
    780000.00,
    15,
    0.18,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
),

(
    1,
    'TECH-SMART-001-WHT',
    '7701000000012',
    'White',
    '128GB',
    'Aluminum',
    'Smartphone X1 - White 128GB',
    1199000.00,
    780000.00,
    15,
    0.18,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
),

(
    1,
    'TECH-SMART-001-BLU',
    '7701000000013',
    'Blue',
    '256GB',
    'Aluminum',
    'Smartphone X1 - Blue 256GB',
    1299000.00,
    850000.00,
    15,
    0.18,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
),

-- Product 2: TechNova Smartphone Pro

(
    2,
    'TECH-SMART-002-BLK',
    '7701000000021',
    'Black',
    '256GB',
    'Aluminum',
    'Smartphone Pro - Black 256GB',
    1799000.00,
    1200000.00,
    10,
    0.20,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd'
),

(
    2,
    'TECH-SMART-002-SLV',
    '7701000000022',
    'Silver',
    '256GB',
    'Aluminum',
    'Smartphone Pro - Silver 256GB',
    1799000.00,
    1200000.00,
    10,
    0.20,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'
),

(
    2,
    'TECH-SMART-002-BLU',
    '7701000000023',
    'Blue',
    '512GB',
    'Aluminum',
    'Smartphone Pro - Blue 512GB',
    1999000.00,
    1350000.00,
    10,
    0.20,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'
),

-- =========================================================
-- LAPTOPS
-- =========================================================

-- Product 3: ByteCore Laptop Air

(
    3,
    'BYTE-LAP-001-SLV',
    '7701000000031',
    'Silver',
    '13-inch',
    'Aluminum',
    'Laptop Air - Silver 13-inch',
    3199000.00,
    2200000.00,
    10,
    1.25,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '1111111111111111111111111111111111111111111111111111111111111111'
),

(
    3,
    'BYTE-LAP-001-GRY',
    '7701000000032',
    'Gray',
    '13-inch',
    'Aluminum',
    'Laptop Air - Gray 13-inch',
    3199000.00,
    2200000.00,
    10,
    1.25,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '2222222222222222222222222222222222222222222222222222222222222222'
),

-- Product 4: ByteCore Laptop Pro

(
    4,
    'BYTE-LAP-002-SLV',
    '7701000000041',
    'Silver',
    '15-inch',
    'Aluminum',
    'Laptop Pro - Silver 15-inch',
    4999000.00,
    3500000.00,
    7,
    1.80,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '3333333333333333333333333333333333333333333333333333333333333333'
),

(
    4,
    'BYTE-LAP-002-BLK',
    '7701000000042',
    'Black',
    '15-inch',
    'Aluminum',
    'Laptop Pro - Black 15-inch',
    4999000.00,
    3500000.00,
    8,
    1.80,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '4444444444444444444444444444444444444444444444444444444444444444'
),

-- =========================================================
-- CLOTHING
-- =========================================================

-- Product 5: UrbanWear Basic T-Shirt

(
    5,
    'URBAN-TS-001-BLK-M',
    '7701000000051',
    'Black',
    'M',
    'Cotton',
    'Basic T-Shirt - Black M',
    69900.00,
    35000.00,
    25,
    0.20,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '5555555555555555555555555555555555555555555555555555555555555555'
),

(
    5,
    'URBAN-TS-001-WHT-L',
    '7701000000052',
    'White',
    'L',
    'Cotton',
    'Basic T-Shirt - White L',
    69900.00,
    35000.00,
    25,
    0.20,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '6666666666666666666666666666666666666666666666666666666666666666'
),

-- Product 6: UrbanWear Premium T-Shirt

(
    6,
    'URBAN-TS-002-BLK-M',
    '7701000000061',
    'Black',
    'M',
    'Organic Cotton',
    'Premium T-Shirt - Black M',
    99900.00,
    50000.00,
    20,
    0.22,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '7777777777777777777777777777777777777777777777777777777777777777'
),

(
    6,
    'URBAN-TS-002-BLU-L',
    '7701000000062',
    'Blue',
    'L',
    'Organic Cotton',
    'Premium T-Shirt - Blue L',
    99900.00,
    50000.00,
    20,
    0.22,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '8888888888888888888888888888888888888888888888888888888888888888'
),

-- =========================================================
-- SHOES
-- =========================================================

-- Product 7: StepPro Running Shoes

(
    7,
    'STEP-SHOE-001-BLK-40',
    '7701000000071',
    'Black',
    '40',
    'Mesh',
    'Running Shoes - Black 40',
    299900.00,
    170000.00,
    15,
    0.75,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '9999999999999999999999999999999999999999999999999999999999999999'
),

(
    7,
    'STEP-SHOE-001-BLK-42',
    '7701000000072',
    'Black',
    '42',
    'Mesh',
    'Running Shoes - Black 42',
    299900.00,
    170000.00,
    15,
    0.78,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '1212121212121212121212121212121212121212121212121212121212121212'
),

-- Product 8: StepPro Casual Shoes

(
    8,
    'STEP-SHOE-002-BRN-41',
    '7701000000081',
    'Brown',
    '41',
    'Leather',
    'Casual Shoes - Brown 41',
    249900.00,
    140000.00,
    12,
    0.90,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '1313131313131313131313131313131313131313131313131313131313131313'
),

(
    8,
    'STEP-SHOE-002-BLK-43',
    '7701000000082',
    'Black',
    '43',
    'Leather',
    'Casual Shoes - Black 43',
    249900.00,
    140000.00,
    13,
    0.95,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '1414141414141414141414141414141414141414141414141414141414141414'
),

-- =========================================================
-- KITCHEN
-- =========================================================

-- Product 9: KitchenPro Coffee Maker

(
    9,
    'KIT-COF-001-BLK',
    '7701000000091',
    'Black',
    'Standard',
    'Stainless Steel',
    'Coffee Maker - Black',
    449900.00,
    260000.00,
    17,
    2.40,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '1515151515151515151515151515151515151515151515151515151515151515'
),

(
    9,
    'KIT-COF-001-SLV',
    '7701000000092',
    'Silver',
    'Standard',
    'Stainless Steel',
    'Coffee Maker - Silver',
    449900.00,
    260000.00,
    18,
    2.40,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '1616161616161616161616161616161616161616161616161616161616161616'
),

-- Product 10: KitchenPro Blender

(
    10,
    'KIT-BLD-001-BLK',
    '7701000000101',
    'Black',
    '1.5L',
    'Plastic',
    'Blender - Black 1.5L',
    329900.00,
    190000.00,
    20,
    2.10,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '1717171717171717171717171717171717171717171717171717171717171717'
),

(
    10,
    'KIT-BLD-001-WHT',
    '7701000000102',
    'White',
    '1.5L',
    'Plastic',
    'Blender - White 1.5L',
    329900.00,
    190000.00,
    20,
    2.10,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '1818181818181818181818181818181818181818181818181818181818181818'
),

-- =========================================================
-- FURNITURE
-- =========================================================

-- Product 11: HomeCraft Office Chair

(
    11,
    'HOME-CHR-001-BLK',
    '7701000000111',
    'Black',
    'Standard',
    'Mesh',
    'Office Chair - Black',
    799900.00,
    450000.00,
    12,
    12.50,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '1919191919191919191919191919191919191919191919191919191919191919'
),

(
    11,
    'HOME-CHR-001-GRY',
    '7701000000112',
    'Gray',
    'Standard',
    'Fabric',
    'Office Chair - Gray',
    799900.00,
    450000.00,
    13,
    12.50,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '2020202020202020202020202020202020202020202020202020202020202020'
),

-- Product 12: HomeCraft Office Desk

(
    12,
    'HOME-DESK-001-BRN',
    '7701000000121',
    'Brown',
    '120cm',
    'Wood',
    'Office Desk - Brown 120cm',
    999900.00,
    580000.00,
    9,
    28.00,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '2121212121212121212121212121212121212121212121212121212121212121'
),

(
    12,
    'HOME-DESK-001-WHT',
    '7701000000122',
    'White',
    '120cm',
    'Wood',
    'Office Desk - White 120cm',
    999900.00,
    580000.00,
    9,
    28.00,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '2222222222222222222222222222222222222222222222222222222222222222'
),

-- =========================================================
-- FITNESS
-- =========================================================

-- Product 13: FitLife Adjustable Dumbbells

(
    13,
    'FIT-DUM-001-BLK-20',
    '7701000000131',
    'Black',
    '20KG',
    'Iron',
    'Adjustable Dumbbells - 20KG',
    499900.00,
    280000.00,
    20,
    20.00,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '2323232323232323232323232323232323232323232323232323232323232323'
),

(
    13,
    'FIT-DUM-001-BLK-30',
    '7701000000132',
    'Black',
    '30KG',
    'Iron',
    'Adjustable Dumbbells - 30KG',
    599900.00,
    340000.00,
    20,
    30.00,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '2424242424242424242424242424242424242424242424242424242424242424'
),

-- Product 14: FitLife Yoga Mat

(
    14,
    'FIT-MAT-001-BLU',
    '7701000000141',
    'Blue',
    'Standard',
    'PVC',
    'Yoga Mat - Blue',
    129900.00,
    60000.00,
    40,
    1.20,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '2525252525252525252525252525252525252525252525252525252525252525'
),

(
    14,
    'FIT-MAT-001-PNK',
    '7701000000142',
    'Pink',
    'Standard',
    'PVC',
    'Yoga Mat - Pink',
    129900.00,
    60000.00,
    40,
    1.20,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '2626262626262626262626262626262626262626262626262626262626262626'
),

-- =========================================================
-- OUTDOOR
-- =========================================================

-- Product 15: OutdoorX Camping Tent

(
    15,
    'OUT-TENT-001-GRN-2P',
    '7701000000151',
    'Green',
    '2-Person',
    'Polyester',
    'Camping Tent - Green 2 Person',
    599900.00,
    330000.00,
    15,
    2.80,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '2727272727272727272727272727272727272727272727272727272727272727'
),

(
    15,
    'OUT-TENT-001-BLU-4P',
    '7701000000152',
    'Blue',
    '4-Person',
    'Polyester',
    'Camping Tent - Blue 4 Person',
    699900.00,
    390000.00,
    15,
    3.60,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '2828282828282828282828282828282828282828282828282828282828282828'
),

-- Product 16: OutdoorX Hiking Backpack

(
    16,
    'OUT-BAG-001-BLK-30',
    '7701000000161',
    'Black',
    '30L',
    'Nylon',
    'Hiking Backpack - Black 30L',
    399900.00,
    220000.00,
    22,
    0.90,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '2929292929292929292929292929292929292929292929292929292929292929'
),

(
    16,
    'OUT-BAG-001-GRN-40',
    '7701000000162',
    'Green',
    '40L',
    'Nylon',
    'Hiking Backpack - Green 40L',
    449900.00,
    250000.00,
    23,
    1.10,
    TRUE,
    'ecommerce_app',
    'BATCH_20260731_007',
    '3030303030303030303030303030303030303030303030303030303030303030'
);