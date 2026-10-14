DROP TABLE IF EXISTS gold.customer_churn_risk;

CREATE TABLE gold.customer_churn_risk AS

WITH base AS (

    SELECT
        user_id,
        username,
        lifetime_value,
        total_orders,
        repeat_orders,
        avg_days_between_orders,
        days_since_last_order,

        total_events,
        login_events,
        product_views,
        cart_additions,
        checkout_started,
        payment_started,
        purchase_events,

        last_event_date,
        engagement_level,
        retention_status,

        is_repeat_customer,
        is_at_risk,
        is_churned

    FROM gold.customer_retention
),

scored AS (

    SELECT
        b.*,

        /*
        RECENCY RISK
        Only applies to customers who have purchased.
        */

        CASE
            WHEN b.total_orders = 0 THEN 0

            WHEN b.days_since_last_order >= 60 THEN 40
            WHEN b.days_since_last_order >= 30 THEN 30
            WHEN b.days_since_last_order >= 14 THEN 20
            WHEN b.days_since_last_order >= 7 THEN 10

            ELSE 0
        END AS recency_risk_points,


        /*
        FREQUENCY RISK
        Non-buyers do not receive churn points.
        */

        CASE
            WHEN b.total_orders = 0 THEN 0

            WHEN b.repeat_orders = 0 THEN 15
            WHEN b.repeat_orders = 1 THEN 5

            ELSE 0
        END AS frequency_risk_points,


        /*
        ENGAGEMENT RISK
        Only relevant for existing customers.
        */

        CASE
            WHEN b.total_orders = 0 THEN 0

            WHEN b.engagement_level = 'NO_ENGAGEMENT'
                THEN 20

            WHEN b.engagement_level = 'LOW_ENGAGEMENT'
                THEN 15

            WHEN b.engagement_level = 'MEDIUM_ENGAGEMENT'
                THEN 5

            ELSE 0
        END AS engagement_risk_points,


        /*
        RETENTION STATUS
        */

        CASE
            WHEN b.total_orders = 0 THEN 0

            WHEN b.retention_status = 'CHURNED'
                THEN 20

            WHEN b.retention_status = 'AT_RISK'
                THEN 15

            ELSE 0
        END AS retention_risk_points

    FROM base b
),

final_scored AS (

    SELECT
        s.*,

        CASE
            WHEN s.total_orders = 0 THEN 0

            ELSE LEAST(
                100,
                s.recency_risk_points
                + s.frequency_risk_points
                + s.engagement_risk_points
                + s.retention_risk_points
            )
        END AS churn_risk_score

    FROM scored s
)

SELECT

    user_id,
    username,

    churn_risk_score,


    /*
    RISK LEVEL
    */

    CASE

        WHEN total_orders = 0
             AND total_events = 0
            THEN 'NO_CUSTOMER'

        WHEN total_orders = 0
             AND total_events > 0
            THEN 'NOT_APPLICABLE'

        WHEN churn_risk_score >= 70
            THEN 'CRITICAL'

        WHEN churn_risk_score >= 50
            THEN 'HIGH'

        WHEN churn_risk_score >= 30
            THEN 'MEDIUM'

        WHEN churn_risk_score > 0
            THEN 'LOW'

        ELSE 'NONE'

    END AS churn_risk_level,


    /*
    BUSINESS SEGMENT
    */

    CASE

        WHEN total_orders = 0
             AND total_events = 0
            THEN 'INACTIVE_NON_CUSTOMER'

        WHEN total_orders = 0
             AND total_events > 0
            THEN 'ENGAGED_NON_BUYER'

        WHEN churn_risk_score >= 70
            THEN 'CRITICAL_CHURN_RISK'

        WHEN churn_risk_score >= 50
            THEN 'HIGH_CHURN_RISK'

        WHEN churn_risk_score >= 30
            THEN 'MODERATE_CHURN_RISK'

        WHEN total_orders > 0
             AND repeat_orders = 0
            THEN 'ONE_TIME_CUSTOMER'

        ELSE 'LOW_CHURN_RISK'

    END AS churn_risk_segment,


    lifetime_value,
    total_orders,
    repeat_orders,
    avg_days_between_orders,
    days_since_last_order,

    total_events,
    login_events,
    product_views,
    cart_additions,
    checkout_started,
    payment_started,
    purchase_events,

    engagement_level,
    retention_status,

    is_repeat_customer,
    is_at_risk,
    is_churned,


    /*
    PRIMARY RISK / OPPORTUNITY REASON
    */

    CASE

        WHEN total_orders = 0
             AND total_events = 0
            THEN 'NO_ACTIVITY'

        WHEN total_orders = 0
             AND total_events > 0
            THEN 'ENGAGED_WITHOUT_PURCHASE'

        WHEN is_churned = TRUE
            THEN 'CUSTOMER_ALREADY_CHURNED'

        WHEN days_since_last_order >= 60
            THEN 'LONG_TIME_SINCE_LAST_PURCHASE'

        WHEN days_since_last_order >= 30
            THEN 'SIGNIFICANT_PURCHASE_GAP'

        WHEN days_since_last_order >= 14
            THEN 'DECLINING_RECENCY'

        WHEN repeat_orders = 0
             AND total_orders > 0
            THEN 'ONE_TIME_PURCHASER'

        WHEN engagement_level = 'NO_ENGAGEMENT'
            THEN 'LOW_ENGAGEMENT'

        ELSE 'NO_MAJOR_RISK_SIGNAL'

    END AS risk_reason,


    /*
    RECOMMENDED BUSINESS ACTION
    */

    CASE

        WHEN total_orders = 0
             AND total_events = 0
            THEN 'NO_ACTION'

        WHEN total_orders = 0
             AND total_events > 0
            THEN 'CONVERSION_CAMPAIGN'

        WHEN is_churned = TRUE
            THEN 'WIN_BACK_CUSTOMER'

        WHEN days_since_last_order >= 60
            THEN 'URGENT_WIN_BACK_CAMPAIGN'

        WHEN days_since_last_order >= 30
            THEN 'RE_ENGAGEMENT_CAMPAIGN'

        WHEN days_since_last_order >= 14
            THEN 'PERSONALIZED_REENGAGEMENT'

        WHEN repeat_orders = 0
             AND total_orders > 0
            THEN 'SECOND_PURCHASE_CAMPAIGN'

        WHEN engagement_level = 'NO_ENGAGEMENT'
            THEN 'REACTIVATION_CAMPAIGN'

        ELSE 'MAINTAIN_ENGAGEMENT'

    END AS recommended_action,


    /*
    REVENUE AT RISK
    Only customers with meaningful churn risk.
    */

    CASE

        WHEN total_orders > 0
             AND churn_risk_score >= 50
            THEN lifetime_value

        ELSE 0

    END AS revenue_at_risk,


    CURRENT_TIMESTAMP AS gold_created_at

FROM final_scored;


CREATE INDEX idx_customer_churn_risk_user
    ON gold.customer_churn_risk(user_id);

CREATE INDEX idx_customer_churn_risk_score
    ON gold.customer_churn_risk(churn_risk_score DESC);

CREATE INDEX idx_customer_churn_risk_level
    ON gold.customer_churn_risk(churn_risk_level);

CREATE INDEX idx_customer_churn_risk_segment
    ON gold.customer_churn_risk(churn_risk_segment);


COMMENT ON TABLE gold.customer_churn_risk IS
    'Customer churn risk scoring and actionable retention signals.';

COMMENT ON COLUMN gold.customer_churn_risk.churn_risk_score IS
    'Composite churn risk score from 0 to 100.';

COMMENT ON COLUMN gold.customer_churn_risk.churn_risk_level IS
    'Categorical churn risk level based on the composite score.';

COMMENT ON COLUMN gold.customer_churn_risk.churn_risk_segment IS
    'Business-oriented customer churn risk segment.';

COMMENT ON COLUMN gold.customer_churn_risk.risk_reason IS
    'Primary observed reason contributing to customer churn risk.';

COMMENT ON COLUMN gold.customer_churn_risk.recommended_action IS
    'Recommended business action based on the customer risk profile.';

COMMENT ON COLUMN gold.customer_churn_risk.revenue_at_risk IS
    'Customer lifetime value exposed to high or critical churn risk.';
