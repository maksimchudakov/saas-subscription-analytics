-- A calendar of month-end dates spanning the data range (Jan 2023 - Jun 2025).
-- This is the "spine" every monthly metric gets joined against.
CREATE OR REPLACE TABLE SAAS_ANALYTICS.MARTS.DATE_SPINE AS
SELECT DATEADD(month, SEQ4(), '2023-01-01')::DATE AS month_start,
       LAST_DAY(DATEADD(month, SEQ4(), '2023-01-01')) AS month_end
FROM TABLE(GENERATOR(ROWCOUNT => 30));

-- For each customer and each month, pull their most recent event as of that
-- month-end. That event's mrr_amount is their MRR for the month (0 if their
-- latest event was a cancel, since cancel events carry mrr_amount = 0).
CREATE OR REPLACE TABLE SAAS_ANALYTICS.MARTS.MONTHLY_MRR AS
SELECT d.month_start, e.customer_id, e.plan, e.mrr_amount
FROM SAAS_ANALYTICS.MARTS.DATE_SPINE d
JOIN SAAS_ANALYTICS.STAGING.SUBSCRIPTION_EVENTS e
    ON e.event_date <= d.month_end
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY d.month_start, e.customer_id
    ORDER BY e.event_date DESC
) = 1;

-- Total MRR trend: the headline SaaS metric, one row per month
SELECT month_start,
    SUM(mrr_amount) AS total_mrr,
    COUNT(CASE WHEN mrr_amount > 0 THEN 1 END) AS active_customers
FROM SAAS_ANALYTICS.MARTS.MONTHLY_MRR
GROUP BY month_start
ORDER BY month_start;
