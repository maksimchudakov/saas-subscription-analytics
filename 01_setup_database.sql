-- Core database for the SaaS subscription analytics project
CREATE DATABASE IF NOT EXISTS SAAS_ANALYTICS;
USE DATABASE SAAS_ANALYTICS;

-- RAW -> STAGING -> MARTS layering keeps each stage independently rebuildable
-- and makes it easy to trace a number back to its source.
CREATE SCHEMA IF NOT EXISTS RAW;       -- source data, untouched
CREATE SCHEMA IF NOT EXISTS STAGING;   -- cleaned, typed, deduplicated
CREATE SCHEMA IF NOT EXISTS MARTS;     -- business-ready tables for BI tools

SHOW WAREHOUSES;
