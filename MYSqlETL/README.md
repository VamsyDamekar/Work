Problem Statement

Organizations need to continuously extract data from relational databases for analytics and reporting. Manual extraction and transformation 
processes are error-prone, inconsistent, and difficult to scale. Automating this workflow while ensuring secure handling of credentials 
and version-controlled deployments is critical for 
maintaining reliable, up-to-date datasets in the cloud.

Target State

Automated Data Extraction: Continuous extraction of employee data from MySQL without manual intervention.

Data Transformation: Apply business logic (e.g., calculated bonus column) to enrich the dataset before storage.

Secure Credential Management: Use environment variables and Jenkins credentials to protect sensitive information.

CI/CD Integration: Automated pipeline triggered via GitHub webhooks to keep the dataset updated.

Cloud Storage: Store processed data in AWS S3 in a structured, date-partitioned format for analytics.

Project Overview

This project implements a Python-based ETL pipeline with end-to-end automation from a MySQL database to AWS S3:

Data Extraction: Employee data is retrieved from a MySQL database using mysql-connector-python.

Data Transformation: Using pandas, a calculated bonus column is added, and the dataset is cleaned for storage.

Data Loading: The transformed dataset is uploaded to S3 in a date-partitioned format (raw/YYYY/MM/DD/employee_data.csv) using boto3.

Secure Environment Management: Sensitive credentials are stored in a .env file locally and in Jenkins credentials for CI/CD runs.

CI/CD Pipeline:

Jenkinsfile defines stages for:

Checking out code from GitHub

Setting up a Python virtual environment

Installing dependencies

Running the ETL script

Archiving logs

The pipeline is triggered automatically via GitHub webhooks whenever code is pushed.

This workflow ensures fully automated, secure, and reproducible ETL from a relational database to cloud storage.

Architecture
MySQL Database → Python ETL Script → AWS S3 (Date-Partitioned CSV)
         ↑
     Jenkins Pipeline
         ↑
     GitHub Webhook Trigger


Description:

MySQL Database: Source of employee data.

Python ETL Script: Extracts, transforms, and prepares data for cloud storage.

AWS S3: Stores cleaned datasets in a date-partitioned structure for downstream analytics.

Jenkins Pipeline: Automates execution, dependency management, and logging.

GitHub Webhook: Triggers pipeline on every code push, enabling CI/CD.

Output

Cleaned and enriched employee dataset with calculated bonus column.

Date-partitioned CSV files in S3 (raw/YYYY/MM/DD/employee_data.csv).

Automated ETL execution via Jenkins with version-controlled scripts.

Fully reproducible pipeline that maintains up-to-date datasets without manual intervention.

