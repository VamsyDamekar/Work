Problem Statement

Handling raw datasets from external sources often requires cleaning, validation, and enrichment before they can be used for 
analytics. Manual data processing is error-prone, time-consuming, and difficult to standardize. There is a need for a structured, 
automated, and reproducible pipeline to transform raw data into analytics-ready datasets.

Target State

Organized Data Storage: Raw, intermediate (staging), and final (curated) datasets stored in separate S3 buckets.

Automated ETL Workflow: Use of AWS Glue jobs to transform data systematically from raw to curated.

Reproducible Infrastructure: IAM roles and permissions set up to allow secure and seamless data processing.

Analytics-Ready Data: Cleaned, validated, and enriched datasets ready for downstream reporting and analysis.

Project Overview

This project implements a well-organized ETL pipeline on AWS to process Kaggle datasets:

Data Ingestion: Dataset downloaded from Kaggle is stored in the raw S3 bucket exactly as-is.

IAM Setup: An IAM role with the necessary permissions is created to allow AWS Glue jobs to access S3 buckets.

First-Level Transformation: AWS Glue job performs basic cleaning and formatting of raw data, storing partially processed data in the 
staging bucket.

Second-Level Transformation: Another AWS Glue job further cleans, validates, and enriches the data, producing the final dataset.

Curated Dataset: Fully processed and analytics-ready data is stored in the curated bucket for reporting and analysis.

Files in Repo:

Glue - Raw to Staged: Executed via script.

Glue Job - Staged to Curated: Executed via script.

ETL Glue Job - 1: Visual editor job from S3 raw → staging.

Glue Job Visual - Staged to Curated: Executed via script.

Architecture
Kaggle Dataset → S3 (Raw) → AWS Glue Job 1 → S3 (Staging) → AWS Glue Job 2 → S3 (Curated) → Analytics / Reporting


Description:

S3 Raw Bucket: Stores the dataset exactly as downloaded.

AWS Glue Job 1: Cleans and formats raw data, saving intermediate results in staging.

S3 Staging Bucket: Holds partially processed data for further transformations.

AWS Glue Job 2: Performs advanced cleaning, validation, and enrichment.

S3 Curated Bucket: Contains final, analytics-ready datasets for downstream use.

Output

Cleaned and validated datasets in the curated bucket.

Intermediate data in staging bucket for traceability.

Fully automated AWS Glue ETL jobs executed via scripts and visual editor.

Structured pipeline that ensures data quality and reproducibility for analytics.
