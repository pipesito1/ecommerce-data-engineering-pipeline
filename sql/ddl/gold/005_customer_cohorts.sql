-- ============================================================
-- GOLD: CUSTOMER COHORT ANALYSIS
-- File: 005_customer_cohorts.sql
-- ============================================================

DROP TABLE IF EXISTS gold.customer_cohorts;

-- ============================================================
-- 1. FIRST PAID ORDER PER CUSTOMER
-- ============================================================

CREATE TABLE gold.customer_cohorts AS

WITH paid_orders AS (

    SELECT
        order_id,
        user_id,
        currency,
        total_amount,
        total_quantity,
        order_date,

        DATE_TRUNC(
            'month',
            order_date
        )::date AS activity_month

    FROM silver.orders

    WHERE payment_status = 'PAID'
      AND cancelled_at IS NULL

),

first_customer_order AS (

    SELECT
        user_id,

        MIN(order_date) AS first_order_date,

        DATE_TRUNC(
            'month',
            MIN(order_date)
        )::date AS cohort_month

    FROM paid_orders

    GROUP BY user_id

),

customer_activity AS (

    SELECT
        po.user_id,
        fco.cohort_month,
        po.activity_month,

        (
            (
                EXTRACT(YEAR FROM po.activity_month)
                - EXTRACT(YEAR FROM fco.cohort_month)
            ) * 12
            +
            (
                EXTRACT(MONTH FROM po.activity_month)
                - EXTRACT(MONTH FROM fco.cohort_month)
            )
        )::integer AS months_since_cohort,

        po.order_id,
        po.currency,
        po.total_amount,
        po.total_quantity

    FROM paid_orders po

    INNER JOIN first_customer_order fco
        ON fco.user_id = po.user_id

),

cohort_sizes AS (

    SELECT
        cohort_month,

        COUNT(DISTINCT user_id) AS cohort_size

    FROM first_customer_order

    GROUP BY cohort_month

),

monthly_activity AS (

    SELECT
        cohort_month,
        activity_month,
        months_since_cohort,

        COUNT(DISTINCT user_id) AS active_customers,

        COUNT(DISTINCT order_id) AS total_orders,

        SUM(total_quantity) AS total_units,

        SUM(total_amount) AS total_revenue,

        AVG(total_amount) AS average_order_value,

        COUNT(DISTINCT user_id)
            FILTER (
                WHERE months_since_cohort = 0
            ) AS new_customers

    FROM customer_activity

    GROUP BY
        cohort_month,
        activity_month,
        months_since_cohort

)

SELECT

    -- ========================================================
    -- Cohort information
    -- ========================================================

    ma.cohort_month,

    ma.activity_month,

    ma.months_since_cohort,

    -- ========================================================
    -- Cohort size
    -- ========================================================

    cs.cohort_size,

    -- ========================================================
    -- Customer activity
    -- ========================================================

    ma.active_customers,

    ma.new_customers,

    -- ========================================================
    -- Retention
    -- ========================================================

    ROUND(
        CASE
            WHEN cs.cohort_size > 0
            THEN
                (
                    ma.active_customers::numeric
                    / cs.cohort_size
                ) * 100
            ELSE 0
        END,
        2
    ) AS retention_rate,

    -- ========================================================
    -- Sales metrics
    -- ========================================================

    ma.total_orders,

    ma.total_units,

    ROUND(
        ma.total_revenue,
        2
    ) AS total_revenue,

    ROUND(
        ma.average_order_value,
        2
    ) AS average_order_value,

    -- ========================================================
    -- Metadata
    -- ========================================================

    CURRENT_TIMESTAMP AS gold_created_at

FROM monthly_activity ma

INNER JOIN cohort_sizes cs
    ON cs.cohort_month = ma.cohort_month

ORDER BY
    ma.cohort_month,
    ma.activity_month;


-- ============================================================
-- 2. INDEXES
-- ============================================================

CREATE INDEX idx_gold_customer_cohorts_cohort
ON gold.customer_cohorts(cohort_month);

CREATE INDEX idx_gold_customer_cohorts_activity
ON gold.customer_cohorts(activity_month);

CREATE INDEX idx_gold_customer_cohorts_months
ON gold.customer_cohorts(months_since_cohort);

CREATE INDEX idx_gold_customer_cohorts_retention
ON gold.customer_cohorts(retention_rate);


-- ============================================================
-- 3. COMMENTS
-- ============================================================

COMMENT ON TABLE gold.customer_cohorts IS
'Gold-level customer cohort analysis based on first paid order and subsequent monthly customer activity.';

COMMENT ON COLUMN gold.customer_cohorts.cohort_month IS
'Month in which the customer placed their first paid order.';

COMMENT ON COLUMN gold.customer_cohorts.activity_month IS
'Month in which the customer generated a paid order.';

COMMENT ON COLUMN gold.customer_cohorts.months_since_cohort IS
'Number of calendar months elapsed since the customer cohort month.';

COMMENT ON COLUMN gold.customer_cohorts.cohort_size IS
'Number of unique customers belonging to the cohort.';

COMMENT ON COLUMN gold.customer_cohorts.active_customers IS
'Number of unique cohort customers with at least one paid order during the activity month.';

COMMENT ON COLUMN gold.customer_cohorts.retention_rate IS
'Percentage of the original cohort that generated a paid order during the activity month.';

COMMENT ON COLUMN gold.customer_cohorts.total_orders IS
'Number of paid orders generated by the cohort during the activity month.';

COMMENT ON COLUMN gold.customer_cohorts.total_units IS
'Total number of units purchased by the cohort during the activity month.';

COMMENT ON COLUMN gold.customer_cohorts.total_revenue IS
'Total revenue from paid orders generated by the cohort during the activity month.';

COMMENT ON COLUMN gold.customer_cohorts.average_order_value IS
'Average paid order value generated by the cohort during the activity month.';