Aug 22: Built generate_data.py with Faker - simulates 1500 SaaS customers 
and 2419 billing events (signup/upgrade/downgrade/cancel) over 2.5 years, 
with seasonal signup patterns and a simulated price-hike churn spike. 
Pushed to GitHub.

Aug 27: Loaded customers.csv and subscription_events.csv into Snowflake RAW 
layer via Snowsight UI upload (chose UI over Python loader for simplicity). 
Hit a header-row parsing error on first attempt - fixed by setting 
"Skip first line" in the CSV load wizard. Built and ran 02_staging.sql to 
create typed/cleaned STAGING.CUSTOMERS and STAGING.SUBSCRIPTION_EVENTS 
tables from RAW. Learned that running a full .sql file in Snowsight only 
executes the statement the cursor is in, not the whole file - need to run 
each CREATE TABLE statement separately. Verified row counts match: 1500 
customers, 2419 events. Pushed 01_setup_database.sql and 02_staging.sql 
to GitHub.

Aug 27: Built 03_marts.sql - date spine + MONTHLY_MRR table reconstructing 
each customer's monthly MRR from their most recent event (QUALIFY + 
ROW_NUMBER). Hit a Snowflake syntax error using FILTER(WHERE...) - fixed 
with COUNT(CASE WHEN...THEN 1 END) instead, which is portable across SQL 
dialects. First real output: Total MRR grew from $8,074 (Jan 2023) to 
$189,891 (Jun 2025) across 899 active customers - simulated price-hike 
churn spike visible as a growth slowdown around Sep-Oct 2024.

Aug 28: Built 04_churn.sql - monthly churn rate using LAG() to compare each 
customer's MRR month-over-month, counting anyone active last month who 
dropped to $0 this month. Baseline churn runs 2-5% most months. Clear spike 
to 7.3-7.4% in Sep-Oct 2024 confirms the simulated price-hike is visible in 
both MRR growth (slowdown) and churn rate (spike) - good validation that 
the synthetic data behaves realistically.

Aug 28: Built 05_cohorts.sql - cohort retention table grouping customers by 
signup month and tracking % still active at each month-since-signup 
(DATEDIFF + FIRST_VALUE window function to normalize against month-0 count). 
Worked correctly on first run. Jan 2023 cohort: 100% at signup, declining to 
69.6% by month 12, 35.7% by month 29 - realistic decay curve. This table is 
ready to become the classic cohort retention heatmap in Tableau.
