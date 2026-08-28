-- Customers, staged for downstream use.
-- signup_date is already DATE-typed in RAW (Snowflake re-inferred it after
-- a bad header row was removed), so this is a clean pass-through for now.
CREATE OR REPLACE TABLE SAAS_ANALYTICS.STAGING.CUSTOMERS AS
SELECT customer_id, company_name, industry, country, segment, signup_date
FROM SAAS_ANALYTICS.RAW.CUSTOMERS;

-- Subscription events, typed and normalized.
-- event_date/mrr_amount already loaded with correct types; standardizing
-- event_type casing here is a defensive habit for when this pipeline
-- eventually ingests less-clean data.
CREATE OR REPLACE TABLE SAAS_ANALYTICS.STAGING.SUBSCRIPTION_EVENTS AS
SELECT event_id, customer_id, event_date,
    LOWER(event_type) AS event_type,
    plan,
    mrr_amount
FROM SAAS_ANALYTICS.RAW.SUBSCRIPTION_EVENTS;

-- Row-count and spot-check
SELECT COUNT(*) FROM SAAS_ANALYTICS.STAGING.CUSTOMERS;
SELECT COUNT(*) FROM SAAS_ANALYTICS.STAGING.SUBSCRIPTION_EVENTS;