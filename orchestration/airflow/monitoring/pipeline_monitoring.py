import hashlib
import os
from datetime import datetime, timezone
from uuid import UUID

import psycopg2


# ============================================================
# POSTGRES CONFIGURATION
# ============================================================

POSTGRES_HOST = os.getenv(
    "POSTGRES_HOST",
    "postgres",
)

POSTGRES_PORT = os.getenv(
    "POSTGRES_PORT",
    "5432",
)

POSTGRES_DB = os.getenv(
    "POSTGRES_DB",
    "ecommerce_db",
)

POSTGRES_USER = os.getenv(
    "POSTGRES_USER",
    "admin",
)

POSTGRES_PASSWORD = os.getenv(
    "POSTGRES_PASSWORD",
)


# ============================================================
# DATABASE CONNECTION
# ============================================================

def get_connection():

    return psycopg2.connect(
        host=POSTGRES_HOST,
        port=POSTGRES_PORT,
        dbname=POSTGRES_DB,
        user=POSTGRES_USER,
        password=POSTGRES_PASSWORD,
    )


# ============================================================
# PIPELINE RUN UUID
# ============================================================

def get_pipeline_run_uuid(context):
    """
    Generates a deterministic UUID for an Airflow DAG run.

    The same DAG run always generates the same UUID.
    """

    dag_id = context["dag"].dag_id

    airflow_run_id = context["dag_run"].run_id

    value = f"{dag_id}:{airflow_run_id}"

    digest = hashlib.md5(
        value.encode("utf-8")
    ).hexdigest()

    return UUID(digest)


# ============================================================
# REGISTER PIPELINE START
# ============================================================

def register_pipeline_start(context):
    """
    Registers the beginning of a pipeline execution.
    """

    pipeline_run_id = get_pipeline_run_uuid(context)

    dag_id = context["dag"].dag_id

    started_at = context["dag_run"].start_date

    if started_at is None:

        started_at = datetime.now(timezone.utc)

    conn = get_connection()

    try:

        with conn.cursor() as cursor:

            cursor.execute(
                """
                INSERT INTO monitoring.pipeline_runs (
                    pipeline_run_id,
                    dag_id,
                    status,
                    started_at
                )
                VALUES (
                    %s,
                    %s,
                    %s,
                    %s
                )
                ON CONFLICT (pipeline_run_id)
                DO NOTHING
                """,
                (
                    pipeline_run_id,
                    dag_id,
                    "RUNNING",
                    started_at,
                ),
            )

        conn.commit()

    finally:

        conn.close()


# ============================================================
# REGISTER PIPELINE END
# ============================================================

def register_pipeline_end(
    context,
    status,
):
    """
    Registers the end of a pipeline execution.
    """

    pipeline_run_id = get_pipeline_run_uuid(context)

    dag_id = context["dag"].dag_id

    finished_at = datetime.now(timezone.utc)

    started_at = context["dag_run"].start_date

    if started_at is None:

        started_at = finished_at

    duration_seconds = (
        finished_at - started_at
    ).total_seconds()

    conn = get_connection()

    try:

        with conn.cursor() as cursor:

            cursor.execute(
                """
                UPDATE monitoring.pipeline_runs
                SET
                    status = %s,
                    finished_at = %s,
                    duration_seconds = %s
                WHERE pipeline_run_id = %s
                  AND dag_id = %s
                """,
                (
                    status,
                    finished_at,
                    duration_seconds,
                    pipeline_run_id,
                    dag_id,
                ),
            )

        conn.commit()

    finally:

        conn.close()


# ============================================================
# REGISTER TASK RUN
# ============================================================

def register_task_run(
    context,
    status,
):
    """
    Registers an individual Airflow task execution.
    """

    pipeline_run_id = get_pipeline_run_uuid(context)

    dag_id = context["dag"].dag_id

    task_id = context["task_instance"].task_id

    started_at = context["task_instance"].start_date

    finished_at = context["task_instance"].end_date

    if started_at is None:

        started_at = datetime.now(timezone.utc)

    if finished_at is None:

        finished_at = datetime.now(timezone.utc)

    duration_seconds = (
        finished_at - started_at
    ).total_seconds()

    error_message = None

    if status == "FAILED":

        exception = context.get("exception")

        if exception:

            error_message = str(exception)

    conn = get_connection()

    try:

        with conn.cursor() as cursor:

            cursor.execute(
                """
                INSERT INTO monitoring.pipeline_task_runs (
                    pipeline_run_id,
                    dag_id,
                    task_id,
                    status,
                    started_at,
                    finished_at,
                    duration_seconds,
                    rows_processed,
                    error_message
                )
                VALUES (
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s
                )
                """,
                (
                    pipeline_run_id,
                    dag_id,
                    task_id,
                    status,
                    started_at,
                    finished_at,
                    duration_seconds,
                    None,
                    error_message,
                ),
            )

        conn.commit()

    finally:

        conn.close()