DROP TABLE IF EXISTS gold.customer_purchase_patterns;

CREATE TABLE gold.customer_purchase_patterns AS
WITH valid_orders AS (
    SELECT
        o.order_id,
        o.user_id,
        o.order_date,
        o.total_amount,
        o.total_quantity,
        o.order_item_count
    FROM silver.orders o
    WHERE o.payment_status = 'PAID'
      AND o.order_status IN ('SHIPPED', 'DELIVERED')
),

order_sequence AS (
    SELECT
        vo.*,
        LAG(vo.order_date) OVER (
            PARTITION BY vo.user_id
            ORDER BY vo.order_date, vo.order_id
        ) AS previous_order_date
    FROM valid_orders vo
),

customer_orders AS (
    SELECT
        user_id,

        COUNT(*) AS total_orders,

        SUM(total_quantity) AS total_units,

        SUM(total_amount) AS lifetime_value,

        AVG(total_amount) AS average_order_value,

        MIN(total_amount) AS minimum_order_value,

        MAX(total_amount) AS maximum_order_value,

        AVG(total_quantity) AS average_units_per_order,

        AVG(order_item_count) AS average_items_per_order,

        COUNT(*) FILTER (
            WHERE previous_order_date IS NOT NULL
        ) AS repeat_orders,

        AVG(
            EXTRACT(
                EPOCH FROM (
                    order_date - previous_order_date
                )
            ) / 86400
        ) FILTER (
            WHERE previous_order_date IS NOT NULL
        ) AS average_days_between_orders,

        MIN(order_date) AS first_order_date,

        MAX(order_date) AS last_order_date,

        COUNT(*) FILTER (
            WHERE EXTRACT(ISODOW FROM order_date) BETWEEN 1 AND 5
        ) AS weekday_orders,

        COUNT(*) FILTER (
            WHERE EXTRACT(ISODOW FROM order_date) IN (6, 7)
        ) AS weekend_orders

    FROM order_sequence
    GROUP BY user_id
),

customer_base AS (
    SELECT
        u.user_id,
        u.username,
        u.country,
        u.currency,
        u.is_active,
        u.is_verified,

        COALESCE(co.total_orders, 0) AS total_orders,
        COALESCE(co.total_units, 0) AS total_units,
        COALESCE(co.lifetime_value, 0) AS lifetime_value,
        COALESCE(co.average_order_value, 0) AS average_order_value,
        COALESCE(co.minimum_order_value, 0) AS minimum_order_value,
        COALESCE(co.maximum_order_value, 0) AS maximum_order_value,
        COALESCE(co.average_units_per_order, 0) AS average_units_per_order,
        COALESCE(co.average_items_per_order, 0) AS average_items_per_order,
        COALESCE(co.repeat_orders, 0) AS repeat_orders,
        COALESCE(co.average_days_between_orders, 0) AS average_days_between_orders,

        co.first_order_date,
        co.last_order_date,

        COALESCE(co.weekday_orders, 0) AS weekday_orders,
        COALESCE(co.weekend_orders, 0) AS weekend_orders

    FROM silver.users u
    LEFT JOIN customer_orders co
        ON u.user_id = co.user_id
),

classified AS (
    SELECT
        cb.*,

        CASE
            WHEN total_orders = 0
                THEN 'NO_PURCHASE'

            WHEN total_orders = 1
                THEN 'ONE_TIME_BUYER'

            WHEN total_orders BETWEEN 2 AND 3
                THEN 'OCCASIONAL_REPEAT_BUYER'

            WHEN total_orders BETWEEN 4 AND 6
                THEN 'FREQUENT_BUYER'

            ELSE 'LOYAL_BUYER'
        END AS purchase_pattern,

        CASE
            WHEN total_orders = 0
                THEN 'NO_PURCHASE'

            WHEN total_orders = 1
                THEN 'LOW_FREQUENCY'

            WHEN average_days_between_orders <= 30
                THEN 'HIGH_FREQUENCY'

            WHEN average_days_between_orders <= 90
                THEN 'MEDIUM_FREQUENCY'

            ELSE 'LOW_FREQUENCY'
        END AS purchase_frequency_segment,

        CASE
            WHEN total_orders = 0
                THEN 'NO_BASKET'

            WHEN average_units_per_order >= 4
                THEN 'LARGE_BASKET'

            WHEN average_units_per_order >= 2
                THEN 'MEDIUM_BASKET'

            ELSE 'SMALL_BASKET'
        END AS basket_size_segment,

        CASE
            WHEN total_orders = 0
                THEN 'NO_PURCHASE'

            WHEN repeat_orders = 0
                THEN 'NO_REPEAT_BEHAVIOR'

            WHEN average_days_between_orders <= 30
                THEN 'RECURRING_MONTHLY'

            WHEN average_days_between_orders <= 90
                THEN 'RECURRING_QUARTERLY'

            ELSE 'OCCASIONAL_REPEAT'
        END AS recurrence_segment,

        CASE
            WHEN total_orders = 0
                THEN 'NO_PURCHASE'

            WHEN weekday_orders > weekend_orders
                THEN 'WEEKDAY_BUYER'

            WHEN weekend_orders > weekday_orders
                THEN 'WEEKEND_BUYER'

            ELSE 'BALANCED_BUYER'
        END AS preferred_purchase_timing

    FROM customer_base cb
)

SELECT
    user_id,
    username,
    country,
    currency,
    is_active,
    is_verified,

    total_orders,
    repeat_orders,
    total_units,

    lifetime_value,
    average_order_value,
    minimum_order_value,
    maximum_order_value,

    average_units_per_order,
    average_items_per_order,
    average_days_between_orders,

    first_order_date,
    last_order_date,

    weekday_orders,
    weekend_orders,

    purchase_pattern,
    purchase_frequency_segment,
    basket_size_segment,
    recurrence_segment,
    preferred_purchase_timing,

    CASE
        WHEN total_orders = 0
            THEN 'NO_CUSTOMER'

        WHEN total_orders = 1
             AND lifetime_value >= 1000000
            THEN 'HIGH_VALUE_ONE_TIME_BUYER'

        WHEN repeat_orders >= 2
             AND average_days_between_orders <= 60
            THEN 'LOYAL_RECURRING_CUSTOMER'

        WHEN repeat_orders >= 1
            THEN 'REPEAT_CUSTOMER'

        WHEN total_orders = 1
            THEN 'ONE_TIME_CUSTOMER'

        ELSE 'STANDARD_CUSTOMER'
    END AS customer_purchase_profile,

    CASE
        WHEN total_orders = 0
            THEN 'NONE'

        WHEN repeat_orders >= 2
             AND average_days_between_orders <= 60
            THEN 'HIGH'

        WHEN repeat_orders >= 1
            THEN 'MEDIUM'

        WHEN total_orders = 1
            THEN 'MEDIUM'

        ELSE 'LOW'
    END AS business_priority,

    CASE
        WHEN total_orders = 0
            THEN 'ACQUISITION_CAMPAIGN'

        WHEN total_orders = 1
             AND lifetime_value >= 1000000
            THEN 'HIGH_VALUE_RETENTION'

        WHEN total_orders = 1
            THEN 'SECOND_PURCHASE_CAMPAIGN'

        WHEN repeat_orders >= 1
             AND average_days_between_orders <= 60
            THEN 'LOYALTY_CAMPAIGN'

        WHEN repeat_orders >= 1
            THEN 'REPEAT_PURCHASE_CAMPAIGN'

        ELSE 'RETENTION_CAMPAIGN'
    END AS recommended_action,

    CURRENT_TIMESTAMP AS gold_created_at

FROM classified;


CREATE INDEX idx_customer_purchase_patterns_user_id
    ON gold.customer_purchase_patterns (user_id);

CREATE INDEX idx_customer_purchase_patterns_pattern
    ON gold.customer_purchase_patterns (purchase_pattern);

CREATE INDEX idx_customer_purchase_patterns_frequency
    ON gold.customer_purchase_patterns (purchase_frequency_segment);

CREATE INDEX idx_customer_purchase_patterns_profile
    ON gold.customer_purchase_patterns (customer_purchase_profile);

CREATE INDEX idx_customer_purchase_patterns_priority
    ON gold.customer_purchase_patterns (business_priority);

CREATE INDEX idx_customer_purchase_patterns_lifetime_value
    ON gold.customer_purchase_patterns (lifetime_value);

COMMENT ON TABLE gold.customer_purchase_patterns IS
'Gold customer-level analysis of purchasing patterns, frequency, recurrence, basket size and purchase behavior.';

COMMENT ON COLUMN gold.customer_purchase_patterns.purchase_pattern IS
'High-level classification of customer purchasing frequency and recurrence.';

COMMENT ON COLUMN gold.customer_purchase_patterns.average_days_between_orders IS
'Average number of days between consecutive paid and shipped/delivered orders.';

COMMENT ON COLUMN gold.customer_purchase_patterns.basket_size_segment IS
'Customer segmentation based on average units purchased per order.';

COMMENT ON COLUMN gold.customer_purchase_patterns.recurrence_segment IS
'Classification of customer repeat-purchase cadence.';

COMMENT ON COLUMN gold.customer_purchase_patterns.customer_purchase_profile IS
'Business-oriented customer purchase profile.';

COMMENT ON COLUMN gold.customer_purchase_patterns.recommended_action IS
'Recommended commercial action based on customer purchasing behavior.';