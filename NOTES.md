Aug 22: Built generate_data.py with Faker - simulates 1500 SaaS customers 
and 2419 billing events (signup/upgrade/downgrade/cancel) over 2.5 years, 
with seasonal signup patterns and a simulated price-hike churn spike. 

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
