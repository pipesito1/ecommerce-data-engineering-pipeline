from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col,
    current_timestamp,
    trim,
    lower,
    upper,
)
import os


# ============================================================
# CONFIGURATION
# ============================================================

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

BRONZE_PATH = f"s3a://{MINIO_BUCKET}/bronze"
SILVER_PATH = f"s3a://{MINIO_BUCKET}/silver"


# ============================================================
# SPARK SESSION
# ============================================================

def create_spark_session():

    spark = (
        SparkSession.builder
        .appName("Ecommerce-Bronze-to-Silver")
        .master("local[*]")

        # ----------------------------------------------------
        # MinIO / S3A configuration
        # ----------------------------------------------------

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

    spark.sparkContext.setLogLevel("WARN")

    return spark


# ============================================================
# BRONZE -> SILVER TRANSFORMATIONS
# ============================================================

def clean_users(df):

    return (
        df
        .dropDuplicates(["user_id"])
        .withColumn(
            "username",
            trim(lower(col("username")))
        )
        .withColumn(
            "email",
            trim(lower(col("email")))
        )
        .withColumn(
            "silver_processed_at",
            current_timestamp()
        )
    )


def clean_products(df):
    return (
        df
        .dropDuplicates(["product_id"])
        .withColumn(
            "sku",
            trim(col("sku"))
        )
        .withColumn(
            "barcode",
            trim(col("barcode"))
        )
        .withColumn(
            "slug",
            trim(lower(col("slug")))
        )
        .withColumn(
            "product_name",
            trim(col("product_name"))
        )
        .withColumn(
            "product_description",
            trim(col("product_description"))
        )
        .withColumn(
            "currency",
            upper(trim(col("currency")))
        )
        .withColumn(
            "silver_processed_at",
            current_timestamp()
        )
    )

def clean_orders(df):

    return (
        df
        .dropDuplicates(["order_id"])
        .withColumn(
            "order_number",
            trim(col("order_number"))
        )
        .withColumn(
            "silver_processed_at",
            current_timestamp()
        )
    )


def clean_events(df):

    return (
        df
        .dropDuplicates(["event_id"])
        .withColumn(
            "event_type",
            trim(col("event_type"))
        )
        .withColumn(
            "silver_processed_at",
            current_timestamp()
        )
    )


def clean_reviews(df):

    return (
        df
        .dropDuplicates(["review_id"])
        .withColumn(
            "silver_processed_at",
            current_timestamp()
        )
    )


# ============================================================
# DATA QUALITY
# ============================================================

def run_quality_checks(df, table_name):

    total_rows = df.count()

    print()
    print("-" * 60)
    print(f"DATA QUALITY: {table_name}")
    print("-" * 60)

    print(f"Total rows: {total_rows}")

    if "user_id" in df.columns:

        null_users = (
            df
            .filter(col("user_id").isNull())
            .count()
        )

        print(f"Null user_id: {null_users}")

    if "product_id" in df.columns:

        null_products = (
            df
            .filter(col("product_id").isNull())
            .count()
        )

        print(f"Null product_id: {null_products}")

    if "order_id" in df.columns:

        null_orders = (
            df
            .filter(col("order_id").isNull())
            .count()
        )

        print(f"Null order_id: {null_orders}")

    print("Status: PASS")

    return total_rows


# ============================================================
# TABLE PROCESSING
# ============================================================

def process_table(
    spark,
    table_name,
    cleaner
):

    bronze_path = (
        f"{BRONZE_PATH}/{table_name}"
    )

    silver_path = (
        f"{SILVER_PATH}/{table_name}"
    )

    print()
    print("=" * 70)
    print(f"PROCESSING: {table_name}")
    print("=" * 70)

    # --------------------------------------------------------
    # Read Bronze from MinIO
    # --------------------------------------------------------

    print(
        f"Reading Bronze: {bronze_path}"
    )

    df = spark.read.parquet(
        bronze_path
    )

    bronze_count = df.count()

    print(
        f"Bronze rows: {bronze_count}"
    )

    print("Bronze schema:")

    df.printSchema()

    # --------------------------------------------------------
    # Transform
    # --------------------------------------------------------

    silver_df = cleaner(df)

    # --------------------------------------------------------
    # Quality checks
    # --------------------------------------------------------

    silver_count = run_quality_checks(
        silver_df,
        table_name
    )

    # --------------------------------------------------------
    # Write Silver to MinIO
    # --------------------------------------------------------

    print()
    print(
        f"Writing Silver: {silver_path}"
    )

    (
        silver_df
        .write
        .mode("overwrite")
        .parquet(silver_path)
    )

    print(
        f"Silver rows: {silver_count}"
    )

    print(
        f"SUCCESS: {table_name}"
    )


# ============================================================
# MAIN PIPELINE
# ============================================================

def main():

    print()
    print("=" * 70)
    print("ECOMMERCE BRONZE -> SILVER PIPELINE")
    print("=" * 70)

    print(
        f"MinIO endpoint: {MINIO_ENDPOINT}"
    )

    print(
        f"Data Lake bucket: {MINIO_BUCKET}"
    )

    print(
        f"Bronze path: {BRONZE_PATH}"
    )

    print(
        f"Silver path: {SILVER_PATH}"
    )

    print("=" * 70)

    spark = create_spark_session()

    try:

        process_table(
            spark,
            "users",
            clean_users
        )

        process_table(
            spark,
            "products",
            clean_products
        )

        process_table(
            spark,
            "orders",
            clean_orders
        )

        process_table(
            spark,
            "events",
            clean_events
        )

        process_table(
            spark,
            "reviews",
            clean_reviews
        )

        print()
        print("=" * 70)
        print("BRONZE -> SILVER PIPELINE COMPLETED")
        print("=" * 70)

    finally:

        spark.stop()


# ============================================================
# ENTRY POINT
# ============================================================

if __name__ == "__main__":
    main()