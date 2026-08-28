-- For each customer, their signup cohort (the month they joined) and how
-- many months have elapsed between their signup and each month in MONTHLY_MRR.
CREATE OR REPLACE TABLE SAAS_ANALYTICS.MARTS.COHORT_RETENTION AS
WITH cohorts AS (
    SELECT customer_id,
        DATE_TRUNC('month', signup_date) AS cohort_month
    FROM SAAS_ANALYTICS.STAGING.CUSTOMERS
),
customer_activity AS (
    SELECT m.customer_id, c.cohort_month, m.month_start,
        DATEDIFF('month', c.cohort_month, m.month_start) AS months_since_signup,
        m.mrr_amount
    FROM SAAS_ANALYTICS.MARTS.MONTHLY_MRR m
    JOIN cohorts c ON c.customer_id = m.customer_id
    WHERE m.month_start >= c.cohort_month
)
SELECT cohort_month, months_since_signup,
    COUNT(DISTINCT customer_id) AS cohort_size_at_signup_or_active,
    COUNT(DISTINCT CASE WHEN mrr_amount > 0 THEN customer_id END) AS active_customers,
    ROUND(
        COUNT(DISTINCT CASE WHEN mrr_amount > 0 THEN customer_id END)
        / NULLIF(FIRST_VALUE(COUNT(DISTINCT CASE WHEN mrr_amount > 0 THEN customer_id END))
            OVER (PARTITION BY cohort_month ORDER BY months_since_signup), 0) * 100, 1
    ) AS retention_pct
FROM customer_activity
GROUP BY cohort_month, months_since_signup
ORDER BY cohort_month, months_since_signup;
