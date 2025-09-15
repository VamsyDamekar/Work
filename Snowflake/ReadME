Problem Statement

A retail company requires a robust and automated data warehouse in Snowflake to support analytics and reporting. The key challenges include:

Ingesting multiple CSV datasets such as customers, products, and sales.

Building a Star Schema with fact and dimension tables to optimize analytical queries.

Handling slowly changing dimensions (SCD) for updates in customer information.

Processing new transactions through change data capture (CDC) to ensure the warehouse is always up to date.

Automating CDC ingestion using Snowflake Streams and Tasks for real-time updates.

Providing secure and optimized views for analysts while maintaining performance and data governance.

Target State

Centralized Data Warehouse: Consolidated and structured storage of customers, products, and sales data.

Star Schema: Optimized fact and dimension tables for fast analytics.

Automated Data Updates: SCD handling for customer updates and CDC ingestion for new transactions.

CI/CD & Automation: Snowflake Streams and Tasks to automate incremental data loads.

Analyst-Ready Views: Secure, optimized views enabling self-service analytics while maintaining data security.

Project Overview

This project implements a Snowflake-based retail data warehouse with end-to-end automation and analytics readiness:

Data Ingestion: CSV files for customers, products, and sales are loaded into staging tables.

Star Schema Construction: Fact and dimension tables are created to organize the data for analytical queries.

Slowly Changing Dimensions (SCD): Customer information is tracked and updated in dimension tables to maintain history.

Change Data Capture (CDC): New sales transactions are captured and applied to the fact table using Snowflake Streams.

Automation: Snowflake Tasks orchestrate CDC pipelines to run at scheduled intervals.

Secure Views: Analyst-friendly, optimized views are provided for reporting without exposing raw data.

Architecture
CSV Files (Customers, Products, Sales) → Staging Tables → SCD & Fact/Dimension Tables → Snowflake Streams & Tasks → Optimized Analyst Views


Description:

Staging Tables: Temporary storage for raw CSVs before transformation.

Dimension Tables: Store customers and products, tracking changes over time (SCD).

Fact Table: Stores sales transactions, updated incrementally using CDC.

Streams & Tasks: Automate the CDC process for real-time updates.

Optimized Views: Secure, analytical-ready datasets for business users.

Output

Fully structured Star Schema in Snowflake (fact + dimension tables).

Updated customer dimension with historical tracking (SCD).

Incremental ingestion of new sales transactions via CDC.

Scheduled automation with Streams and Tasks for continuous data availability.

Secure, optimized views for analysts to perform reporting and analytics.
