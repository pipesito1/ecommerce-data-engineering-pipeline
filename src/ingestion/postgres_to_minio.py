from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp
import os


# ============================================================
# CONFIGURATION
# ============================================================

POSTGRES_HOST = os.getenv("POSTGRES_HOST", "postgres")
POSTGRES_PORT = os.getenv("POSTGRES_PORT", "5432")
POSTGRES_DB = os.getenv("POSTGRES_DB", "ecommerce_db")
POSTGRES_USER = os.getenv("POSTGRES_USER", "admin")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD")

MINIO_ENDPOINT = os.getenv(
    "MINIO_ENDPOINT",
    "http://minio:9000"
)

MINIO_BUCKET = os.getenv(
    "MINIO_BUCKET",
    "ecommerce-data-lake"
)

MINIO_ACCESS_KEY = os.getenv(
    "MINIO_ROOT_USER"
)

MINIO_SECRET_KEY = os.getenv(
    "MINIO_ROOT_PASSWORD"
)


# ============================================================
# SPARK SESSION
# ============================================================

spark = (
    SparkSession.builder
    .appName("PostgreSQL-to-MinIO-Bronze")

    # --------------------------------------------------------
    # MinIO / S3 configuration
    # --------------------------------------------------------

    .config(
        "spark.hadoop.fs.s3a.endpoint",
        MINIO_ENDPOINT
    )
    .config(
        "spark.hadoop.fs.s3a.access.key",
        MINIO_ACCESS_KEY
    )
    .config(
        "spark.hadoop.fs.s3a.secret.key",
        MINIO_SECRET_KEY
    )
    .config(
        "spark.hadoop.fs.s3a.path.style.access",
        "true"
    )
    .config(
        "spark.hadoop.fs.s3a.connection.ssl.enabled",
        "false"
    )
    .config(
        "spark.hadoop.fs.s3a.impl",
        "org.apache.hadoop.fs.s3a.S3AFileSystem"
    )

    .getOrCreate()
)


# ============================================================
# POSTGRESQL CONNECTION
# ============================================================

jdbc_url = (
    f"jdbc:postgresql://"
    f"{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}"
)

jdbc_properties = {
    "user": POSTGRES_USER,
    "password": POSTGRES_PASSWORD,
    "driver": "org.postgresql.Driver"
}


# ============================================================
# TABLES TO INGEST
# ============================================================

TABLES = [
    "users",
    "products",
    "orders",
    "events",
    "reviews"
]


# ============================================================
# INGESTION PROCESS
# ============================================================

for table in TABLES:

    print("=" * 70)
    print(f"INGESTING: bronze.{table}")
    print("=" * 70)

    # --------------------------------------------------------
    # PostgreSQL source table
    # --------------------------------------------------------

    source_table = f"bronze.{table}"

    print(
        f"Reading from PostgreSQL: {source_table}"
    )

    df = spark.read.jdbc(
        url=jdbc_url,
        table=source_table,
        properties=jdbc_properties
    )

    # --------------------------------------------------------
    # Count rows
    # --------------------------------------------------------

    row_count = df.count()

    print(
        f"Rows read: {row_count}"
    )

    print(
        f"Columns: {len(df.columns)}"
    )

    # --------------------------------------------------------
    # Add ingestion timestamp
    # --------------------------------------------------------

    df = df.withColumn(
        "lake_ingestion_timestamp",
        current_timestamp()
    )

    # --------------------------------------------------------
    # MinIO destination
    # --------------------------------------------------------

    output_path = (
        f"s3a://{MINIO_BUCKET}/bronze/{table}"
    )

    print(
        f"Writing to MinIO: {output_path}"
    )

    # --------------------------------------------------------
    # Write as Parquet
    # --------------------------------------------------------

    df.write \
        .mode("overwrite") \
        .parquet(output_path)

    print(
        f"Completed: bronze.{table}"
    )

    print()


# ============================================================
# FINISH
# ============================================================

print("=" * 70)
print("BRONZE INGESTION COMPLETED SUCCESSFULLY")
print("=" * 70)

spark.stop()