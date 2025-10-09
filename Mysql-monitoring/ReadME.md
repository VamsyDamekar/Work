MySQL Monitoring with Prometheus & Grafana
Problem Statement

Monitoring MySQL performance and query metrics is essential to ensure database reliability, optimize performance, and detect issues early. 
Manual monitoring is inefficient and error-prone, and without centralized metrics, performance bottlenecks can go unnoticed, leading to 
degraded application experience.

Target State

Automated monitoring of MySQL database metrics.

Centralized dashboard displaying query counts, questions, uptime, and other key performance metrics.

Real-time alerts and insights for database performance and health.

Scalable and reproducible setup using Prometheus for metrics collection and Grafana for visualization.

Project Overview

This project implements a complete MySQL monitoring solution using Prometheus, Grafana, and mysqld_exporter. It collects metrics 
from MySQL, scrapes them via Prometheus, and visualizes them in Grafana dashboards. The project also includes scripts to start exporters 
and configuration files for both Prometheus and Grafana.

Architecture
MySQL Database
       |
       v
mysqld_exporter --> Prometheus --> Grafana
       |               |
       |               v
       |          Metric Storage
       v
  Metrics Collection


mysqld_exporter: Connects to MySQL and exposes metrics over HTTP.

Prometheus: Scrapes metrics from mysqld_exporter at configured intervals and stores them in its time-series database.

Grafana: Connects to Prometheus to visualize metrics via dashboards.

Scripts: Automate starting exporters and managing configurations.

Description

Prometheus Configuration: Defined in prometheus/prometheus.yml to scrape MySQL metrics every 15 seconds.

Grafana Dashboards: Pre-configured JSON dashboards in grafana/dashboards/mysql-dashboard.json show query counts, questions, and uptime.

MySQL Config: .my.cnf contains credentials for mysqld_exporter (ignored in Git for security).

Scripts: start_exporter.sh launches mysqld_exporter with proper configuration.

Git Structure: Organized folder structure ensures clarity, modularity, and ease of maintenance.

Output

Once the setup is running:

Prometheus collects metrics from MySQL every 15 seconds.

Grafana dashboards display:

mysql_up → Shows MySQL server uptime.

mysql_global_status_queries → Number of queries executed.

mysql_global_status_questions → Number of questions sent to the server.

Real-time insights allow monitoring database health and identifying performance bottlenecks.

Metrics can be extended for additional MySQL statistics like connections, slow queries, and replication status.
