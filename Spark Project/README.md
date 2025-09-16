Problem Statement

Retail companies often handle large transactional datasets that require cleaning, enrichment, and aggregation to derive actionable insights. Processing this data efficiently at scale is challenging without distributed computing. Key challenges include:

Handling duplicates, nulls, and invalid records.

Enriching transactional data with derived metrics and time-based attributes.

Aggregating and summarizing data at multiple levels (country, region, product category).

Optimizing Spark jobs for performance using partitioning and caching.

Storing curated outputs in a format suitable for analytics and reporting.

Target State

Clean and Curated Dataset: Remove invalid data and enrich with calculated metrics.

Aggregated Insights: Summaries at country, region, and monthly category levels.

Performance Optimized Pipeline: Efficient Spark jobs with caching and partition tuning.

Analytics-Ready Output: Store results as compressed Parquet files for downstream use.

Project Overview

This project implements a PySpark-based retail analytics pipeline:

Spark Session & Context: Initialize SparkSession and SparkContext to run distributed processing.

Load & Preview: Read transactional CSV data into Spark DataFrame and inspect its structure.

Data Cleaning:

Remove duplicates.

Drop rows with null customer IDs.

Filter out orders with non-positive quantities.

Data Enrichment:

Add an order_value column (quantity × price).

Extract year, month, and day from the timestamp for time-based analysis.

Country Revenue Summary: Compute total sales per country.

Top Customer per Country: Rank customers by spend and retain the highest spender per country.

Region Join & Summary: Join country-to-region lookup and aggregate sales by region.

Monthly Category Pivot: Create pivot table of monthly sales per product category.

Price Band Counts: Bucket orders into price ranges and count orders per band.

Partition Tuning Check: Repartition data and compare job performance.

Cache vs. Recompute: Measure speedup achieved by caching intermediate results.

Write Gold Output: Save curated revenue tables as compressed Parquet files for downstream analytics.

Architecture
CSV Input → Spark DataFrame → Clean → Enrich → Aggregations & Summaries → Performance Optimization → Parquet Output


Description:

Input: Raw CSV transactional data.

Spark Processing: Distributed cleaning, enrichment, and aggregation.

Aggregations: Country revenue, top customer, regional sales, monthly category pivot, price band counts.

Performance Tuning: Partitioning and caching to optimize job runtime.

Output: Curated Parquet files for analytics.

Output

Cleaned and enriched transaction dataset with order_value and timestamp breakdown.

Aggregated sales summaries: country-level, region-level, and monthly category-level.

Top customer per country and price band counts.

Curated Parquet files ready for reporting and analytics.

Performance-optimized Spark pipeline demonstrating caching and partition tuning.
