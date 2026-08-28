-- Churn rate by month: % of last month's active customers who are inactive this month.
-- Uses LAG to look at each customer's prior-month MRR alongside their current MRR.
CREATE OR REPLACE TABLE SAAS_ANALYTICS.MARTS.MONTHLY_CHURN AS
WITH customer_month_status AS (
    SELECT month_start, customer_id, mrr_amount,
        LAG(mrr_amount) OVER (PARTITION BY customer_id ORDER BY month_start
        ) AS prev_month_mrr
    FROM SAAS_ANALYTICS.MARTS.MONTHLY_MRR
)
SELECT
    month_start,
    COUNT(CASE WHEN prev_month_mrr > 0 THEN 1 END) AS active_last_month,
    COUNT(CASE WHEN prev_month_mrr > 0 AND mrr_amount = 0 THEN 1 END) AS churned_this_month,
    ROUND(
        COUNT(CASE WHEN prev_month_mrr > 0 AND mrr_amount = 0 THEN 1 END)
        / NULLIF(COUNT(CASE WHEN prev_month_mrr > 0 THEN 1 END), 0) * 100, 2
    ) AS churn_rate_pct
FROM customer_month_status
GROUP BY month_start
ORDER BY month_start;
