from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp
import os


# ============================================================
# SILVER → POSTGRESQL
# Load Silver Parquet data from MinIO into PostgreSQL
# ============================================================

POSTGRES_HOST = os.getenv("POSTGRES_HOST", "postgres")
POSTGRES_PORT = os.getenv("POSTGRES_PORT", "5432")
POSTGRES_DB = os.getenv("POSTGRES_DB", "ecommerce_db")
POSTGRES_USER = os.getenv("POSTGRES_USER", "admin")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD")

MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "http://minio:9000")
MINIO_BUCKET = os.getenv("MINIO_BUCKET", "ecommerce-data-lake")
MINIO_ACCESS_KEY = os.getenv("MINIO_ROOT_USER")
MINIO_SECRET_KEY = os.getenv("MINIO_ROOT_PASSWORD")


# ============================================================
# SPARK SESSION
# ============================================================

spark = (
    SparkSession.builder
    .appName("Silver-MinIO-to-PostgreSQL")
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
# POSTGRESQL JDBC CONFIGURATION
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
# SILVER TABLES
# ============================================================

TABLES = [
    "users",
    "products",
    "orders",
    "events",
    "reviews",
]


# ============================================================
# SILVER → POSTGRESQL
# ============================================================

for table in TABLES:

    print("=" * 70)
    print(f"LOADING SILVER: {table}")
    print("=" * 70)

    # --------------------------------------------------------
    # Read Silver data from MinIO
    # --------------------------------------------------------

    input_path = (
        f"s3a://{MINIO_BUCKET}/silver/{table}"
    )

    print("Reading Silver Parquet from MinIO:")
    print(input_path)

    df = spark.read.parquet(input_path)

    # --------------------------------------------------------
    # Basic information
    # --------------------------------------------------------

    row_count = df.count()

    print(f"Rows read: {row_count}")
    print(f"Columns: {len(df.columns)}")

    print("Schema:")
    df.printSchema()

    # --------------------------------------------------------
    # Add PostgreSQL load timestamp
    # --------------------------------------------------------

    df = df.withColumn(
        "postgres_load_timestamp",
        current_timestamp()
    )

    # --------------------------------------------------------
    # PostgreSQL target table
    # --------------------------------------------------------

    target_table = f"silver.{table}"

    print("Writing to PostgreSQL:")
    print(target_table)

    (
    df.write
    .mode("overwrite")
    .option("truncate", "true")
    .jdbc(
        url=jdbc_url,
        table=target_table,
        properties=jdbc_properties
    )
)

    print(f"Completed: {target_table}")
    print()


# ============================================================
# PIPELINE COMPLETED
# ============================================================

print("=" * 70)
print("SILVER → POSTGRESQL COMPLETED SUCCESSFULLY")
print("=" * 70)


# ============================================================
# STOP SPARK
# ============================================================

spark.stop()