<div align="center">
 # E-Commerce Data Engineering Pipeline

<img src="ecommerce-data-engineering-pipeline.jfif">

An end-to-end data engineering project that demonstrates how to ingest, transform, validate, and monitor e-commerce data using a modern data platform.

</div>

## Project Overview

This project implements a containerized data pipeline for processing e-commerce data from PostgreSQL through a Bronze and Silver data lake architecture, with data transformation, quality checks, and pipeline monitoring.

The goal is to demonstrate practical data engineering skills, including batch ingestion, distributed processing, orchestration, analytical modeling, and operational monitoring.

## Architecture

The pipeline follows this workflow:

PostgreSQL → MinIO Bronze Data Lake → PySpark Transformations → Silver Layer in PostgreSQL → dbt Models and Tests → Data Quality Checks → Monitoring

### Data Layers

- **Bronze:** Raw source data stored as Parquet files in MinIO.
- **Silver:** Processed and standardized data loaded into PostgreSQL.
- **Analytics:** dbt models for analytical transformations.
- **Monitoring:** Pipeline execution history, task status, duration, and data quality results.

## Technology Stack

- **Python** — ingestion and pipeline utilities
- **PostgreSQL** — relational storage and analytical data
- **MinIO** — S3-compatible object storage
- **Apache Spark / PySpark** — distributed data transformations
- **Apache Airflow** — workflow orchestration
- **dbt** — SQL-based transformations and data tests
- **Docker** — containerized services
- **Power BI** — business and pipeline monitoring dashboards

## Pipeline Workflow

The Airflow DAG orchestrates the following tasks:

1. `start_pipeline` — initialize the pipeline run.
2. `postgres_to_minio` — extract source tables and write Parquet files to Bronze storage.
3. `bronze_to_silver` — transform Bronze data using PySpark.
4. `silver_to_postgres` — load transformed data into PostgreSQL.
5. `dbt_run` — execute analytical transformation models.
6. `dbt_test` — validate dbt model assumptions and data integrity.
7. `data_quality` — execute data quality checks and record their results.
8. `pipeline_end` — finalize the pipeline run.

## Data Quality and Monitoring

The project records pipeline and task execution information, including statuses and execution durations.

Data quality results are stored in PostgreSQL and can be used to investigate validation failures and monitor the quality of processed data.

## Dashboards

The project includes Power BI reporting for:

- **E-Commerce Overview:** business and customer analytics.
- **Pipeline Monitoring:** pipeline execution and operational monitoring.

## Getting Started

### Prerequisites

- Docker Desktop
- Git
- PowerShell on Windows, or an equivalent terminal
- Power BI Desktop to open and explore the dashboards

### 1. Clone the repository

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
cd ecommerce-data-engineering-pipeline
```

### 2. Configure environment variables

Create a local environment file from the example:

```powershell
Copy-Item .env.example .env
```

Update `.env` with your local configuration. Never commit `.env` or publish real credentials.

### 3. Build and start the services

```bash
docker compose up --build -d
```

### 4. Inspect the running containers

```bash
docker compose ps
```

### 5. Access Airflow

When the services are running and Airflow is initialized, open:

http://localhost:8081

Use the configured local Airflow credentials.

> Service initialization and credentials depend on the local configuration. Review `docker-compose.yml` and the environment example before starting the stack.

## Repository Structure

```text
.
├── analytics/       # dbt project and analytical models
├── docs/            # Architecture documentation and decision records
├── orchestration/   # Airflow DAGs and monitoring utilities
├── sql/             # Database DDL and DML scripts
├── src/
│   ├── ingestion/   # Source ingestion
│   ├── transformations/
│   └── quality/     # Data quality checks
├── Dockerfile.airflow
├── Dockerfile.dbt
├── Dockerfile.spark
├── docker-compose.yml
├── .env.example
├── .gitignore
└── PROJECT_CHARTER.md
```

## Security

- Store credentials in local environment variables.
- Keep `.env` out of version control.
- Do not commit passwords, access keys, tokens, or other secrets.
- Use `.env.example` to document required configuration with placeholder values.

## Project Status

The core pipeline, analytical transformations, data quality checks, monitoring tables, and dashboards have been implemented. The repository is being prepared for public release, including documentation and a final review of configuration and generated files.

## Author

JESUS FELIPE SEPULVEDA ALVAREZ
Data Engineering Portfolio Project
