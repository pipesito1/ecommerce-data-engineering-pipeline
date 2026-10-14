import os
import sys

from datetime import datetime

from airflow import DAG
from airflow.operators.python import PythonOperator, get_current_context
from airflow.providers.docker.operators.docker import DockerOperator
from airflow.utils.trigger_rule import TriggerRule
from docker.types import Mount

sys.path.append("/opt/airflow/monitoring")

from pipeline_monitoring import (
    register_pipeline_start,
    register_pipeline_end,
    register_task_run,
)


def task_success_callback(context):
    register_task_run(context, "SUCCESS")


def task_failure_callback(context):
    register_task_run(context, "FAILED")
    register_pipeline_end(context, "FAILED")


def start_pipeline():
    print("=" * 70)
    print("E-COMMERCE DATA ENGINEERING PIPELINE")
    print("=" * 70)
    print("Pipeline started successfully")
    print("=" * 70)


def finish_pipeline():
    """
    Marks the pipeline as successfully completed.

    This task only runs when all upstream tasks succeed.
    """

    context = get_current_context()

    print("=" * 70)
    print("PIPELINE FINISHED SUCCESSFULLY")
    print("=" * 70)

    register_pipeline_end(context, "SUCCESS")

    print("Pipeline monitoring updated to SUCCESS.")
    print("=" * 70)

NETWORK = "ecommerce-data-engineering-pipeline_default"

SPARK_IMAGE = "ecommerce-spark:4.2.0"
DBT_IMAGE = "ecommerce-dbt:1.0"

PROJECT_SRC = (
    r"C:\Users\Master\Documents\Data_project"
    r"\ecommerce-data-engineering-pipeline\src"
)

PROJECT_DBT = (
    r"C:\Users\Master\Documents\Data_project"
    r"\ecommerce-data-engineering-pipeline\analytics\dbt"
)

SPARK_SRC_MOUNT = Mount(
    source=PROJECT_SRC,
    target="/opt/spark-apps/src",
    type="bind",
)

DBT_MOUNT = Mount(
    source=PROJECT_DBT,
    target="/usr/app/dbt",
    type="bind",
)

SPARK_ENV = {
    "POSTGRES_HOST": os.getenv("POSTGRES_HOST", "postgres"),
    "POSTGRES_PORT": os.getenv("POSTGRES_PORT", "5432"),
    "POSTGRES_DB": os.getenv("POSTGRES_DB", "ecommerce_db"),
    "POSTGRES_USER": os.getenv("POSTGRES_USER", "admin"),
    "POSTGRES_PASSWORD": os.getenv("POSTGRES_PASSWORD"),

    "MINIO_ENDPOINT": os.getenv(
        "MINIO_ENDPOINT",
        "http://minio:9000",
    ),

    "MINIO_BUCKET": os.getenv(
        "MINIO_BUCKET",
        "ecommerce-data-lake",
    ),

    "MINIO_ROOT_USER": os.getenv("MINIO_ROOT_USER"),
    "MINIO_ROOT_PASSWORD": os.getenv(
        "MINIO_ROOT_PASSWORD"
    ),

    "AWS_ACCESS_KEY_ID": os.getenv("MINIO_ROOT_USER"),
    "AWS_SECRET_ACCESS_KEY": os.getenv(
        "MINIO_ROOT_PASSWORD"
    ),
}


DBT_ENV = {
    "DBT_PROFILES_DIR": "/usr/app/dbt",

    "POSTGRES_HOST": "postgres",
    "POSTGRES_PORT": "5432",
    "POSTGRES_DB": "ecommerce_db",
    "POSTGRES_USER": "admin",
    "POSTGRES_PASSWORD": os.getenv(
        "POSTGRES_PASSWORD"
    ),
}


with DAG(
    dag_id="ecommerce_pipeline",

    start_date=datetime(2026, 1, 1),

    schedule=None,
    catchup=False,

    default_args={
        "on_success_callback": task_success_callback,
        "on_failure_callback": task_failure_callback,
    },

    tags=[
        "ecommerce",
        "data-engineering",
        "spark",
        "dbt",
        "monitoring",
    ],

) as dag:

    start = PythonOperator(
        task_id="start_pipeline",

        python_callable=start_pipeline,

        on_execute_callback=register_pipeline_start,
    )


    postgres_to_minio = DockerOperator(
        task_id="postgres_to_minio",

        image=SPARK_IMAGE,

        command=(
            "/opt/spark/bin/spark-submit "
            "/opt/spark-apps/src/ingestion/"
            "postgres_to_minio.py"
        ),

        network_mode=NETWORK,

        docker_url="unix://var/run/docker.sock",

        mounts=[
            SPARK_SRC_MOUNT
        ],

        environment=SPARK_ENV,

        auto_remove="success",

        mount_tmp_dir=False,
    )


    bronze_to_silver = DockerOperator(
        task_id="bronze_to_silver",

        image=SPARK_IMAGE,

        command=(
            "/opt/spark/bin/spark-submit "
            "/opt/spark-apps/src/transformations/"
            "bronze_to_silver.py"
        ),

        network_mode=NETWORK,

        docker_url="unix://var/run/docker.sock",

        mounts=[
            SPARK_SRC_MOUNT
        ],

        environment=SPARK_ENV,

        auto_remove="success",

        mount_tmp_dir=False,
    )


    silver_to_postgres = DockerOperator(
        task_id="silver_to_postgres",

        image=SPARK_IMAGE,

        command=(
            "/opt/spark/bin/spark-submit "
            "/opt/spark-apps/src/transformations/"
            "silver_to_postgres.py"
        ),

        network_mode=NETWORK,

        docker_url="unix://var/run/docker.sock",

        mounts=[
            SPARK_SRC_MOUNT
        ],

        environment=SPARK_ENV,

        auto_remove="success",

        mount_tmp_dir=False,
    )


    dbt_run = DockerOperator(
        task_id="dbt_run",

        image=DBT_IMAGE,

        command="dbt run",

        network_mode=NETWORK,

        docker_url="unix://var/run/docker.sock",

        mounts=[
            DBT_MOUNT
        ],

        environment=DBT_ENV,

        working_dir="/usr/app/dbt",

        auto_remove="success",

        mount_tmp_dir=False,
    )


    dbt_test = DockerOperator(
        task_id="dbt_test",

        image=DBT_IMAGE,

        command="dbt test",

        network_mode=NETWORK,

        docker_url="unix://var/run/docker.sock",

        mounts=[
            DBT_MOUNT
        ],

        environment=DBT_ENV,

        working_dir="/usr/app/dbt",

        auto_remove="success",

        mount_tmp_dir=False,
    )


    data_quality = DockerOperator(
        task_id="data_quality",

        image="ecommerce-airflow:1.0",

        command=(
            "python "
            "/opt/airflow/src/quality/"
            "run_quality_checks.py"
        ),

        network_mode=NETWORK,

        docker_url="unix://var/run/docker.sock",

        mounts=[
            Mount(
                source=PROJECT_SRC,
                target="/opt/airflow/src",
                type="bind",
            )
        ],

        environment=DBT_ENV,

        auto_remove="success",

        mount_tmp_dir=False,
    )


    pipeline_end = PythonOperator(
        task_id="pipeline_end",

        python_callable=finish_pipeline,

        trigger_rule=TriggerRule.ALL_SUCCESS,
    )


    (
        start
        >> postgres_to_minio
        >> bronze_to_silver
        >> silver_to_postgres
        >> dbt_run
        >> dbt_test
        >> data_quality
        >> pipeline_end
    )