ETL Pipeline with Terraform, AWS Lambda, Step Functions, and Athena

Problem Statement
A business needs to periodically extract data from a transactional relational database (MySQL or PostgreSQL) and store it in a centralized 
data lake for analytics and reporting. Manual exports are error-prone and time-consuming. The solution should automate the entire batch 
pipeline from database to AWS S3, apply transformations, and expose curated data for SQL-based analytics.

Target State
The target state is a serverless batch ETL pipeline on AWS where:

Data is extracted from MySQL/PostgreSQL every 15 minutes using a scheduled Python script.

Extracted data is uploaded to a raw S3 bucket.

A Lambda function cleans and transforms the raw data and writes it to a curated S3 bucket.

Athena provides SQL querying capability on curated data.

Step Functions orchestrate tasks for reliability.

CloudWatch and SNS provide monitoring and alerting.

Project Overview
This project provisions the entire ETL flow:

Database Export (Section 1): Python script connects to MySQL/PostgreSQL, extracts new records (e.g., last 15 mins), and uploads them as CSV 
to the raw S3 bucket. Script is automated with cron (Linux/macOS) or Task Scheduler (Windows).

Raw Data Ingestion (Section 2): Files land in the /raw/ prefix of the S3 bucket.

Transformation (Section 2): Lambda function validates, deduplicates, and enriches data, then writes results into /curated/ prefix of the 
curated bucket.

Query Layer (Section 3): Athena is configured to run SQL queries on curated data for validation and analytics.

Orchestration (Section 4): AWS Step Functions optionally orchestrate the ETL steps and can be scheduled with EventBridge.

Monitoring & Alerts (Section 5): CloudWatch captures logs and errors, while SNS notifies stakeholders on failures.

Files in Repo:

main.tf → Terraform code for AWS infra (S3, Lambda, Step Functions, Athena, SNS, IAM).

Script.py → Python script to extract data from MySQL/PostgreSQL and upload to raw S3 bucket.

lambda_function.py → Lambda transformation script.

lambda_function.zip → Deployment package for Lambda.

README.txt → Documentation of the project.

Description:

Section 1: Connects to MySQL/PostgreSQL using credentials, extracts incremental data, saves as CSV, uploads to rawbt1 bucket. 
Script scheduled every 15 minutes with cron or Task Scheduler.

Section 2: Lambda listens to raw bucket uploads, transforms data, and writes to curatedbt1.

Section 3: Athena database/table points to curated bucket for querying.

Section 4: Step Functions automate the workflow and EventBridge can trigger it periodically.

Section 5: CloudWatch monitors Lambda/Step Functions logs, while SNS sends email alerts on pipeline errors.

Output

Raw Data: s3://rawbt1/ (uploaded CSVs from database export).

Curated Data: s3://curatedbt1/ (clean, queryable data).

Athena: Run SQL queries against curated tables for analytics.

Alerts: SNS sends notifications when Lambda or Step Functions fail.
