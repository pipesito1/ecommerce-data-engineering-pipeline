import os
import uuid

import psycopg2


POSTGRES_HOST = os.getenv("POSTGRES_HOST", "postgres")
POSTGRES_PORT = os.getenv("POSTGRES_PORT", "5432")
POSTGRES_DB = os.getenv("POSTGRES_DB", "ecommerce_db")
POSTGRES_USER = os.getenv("POSTGRES_USER", "admin")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD")


RUN_ID = uuid.uuid4()


def get_connection():
    return psycopg2.connect(
        host=POSTGRES_HOST,
        port=POSTGRES_PORT,
        database=POSTGRES_DB,
        user=POSTGRES_USER,
        password=POSTGRES_PASSWORD,
    )


def save_result(
    cursor,
    table_schema,
    table_name,
    check_name,
    status,
    expected_value,
    actual_value,
    message,
):
    cursor.execute(
        """
        INSERT INTO monitoring.data_quality_results (
            run_id,
            table_schema,
            table_name,
            check_name,
            status,
            expected_value,
            actual_value,
            message
        )
        VALUES (
            %s, %s, %s, %s, %s, %s, %s, %s
        )
        """,
        (
            str(RUN_ID),
            table_schema,
            table_name,
            check_name,
            status,
            str(expected_value),
            str(actual_value),
            message,
        ),
    )

    print(
        f"[{status}] "
        f"{table_schema}.{table_name} | "
        f"{check_name} | "
        f"{message}"
    )


def check_table_not_empty(cursor, table_name):
    cursor.execute(
        f"""
        SELECT COUNT(*)
        FROM silver.{table_name}
        """
    )

    count = cursor.fetchone()[0]

    if count > 0:
        return (
            "PASS",
            "> 0",
            count,
            f"Table contains {count} records.",
        )

    return (
        "FAIL",
        "> 0",
        count,
        "Table is empty.",
    )


def check_nulls(cursor, table_name, column_name):
    cursor.execute(
        f"""
        SELECT COUNT(*)
        FROM silver.{table_name}
        WHERE {column_name} IS NULL
        """
    )

    null_count = cursor.fetchone()[0]

    if null_count == 0:
        return (
            "PASS",
            "0",
            null_count,
            f"No NULL values found in {column_name}.",
        )

    return (
        "FAIL",
        "0",
        null_count,
        f"Found {null_count} NULL values in {column_name}.",
    )


def check_duplicates(cursor, table_name, column_name):
    cursor.execute(
        f"""
        SELECT COUNT(*)
        FROM (
            SELECT {column_name}
            FROM silver.{table_name}
            GROUP BY {column_name}
            HAVING COUNT(*) > 1
        ) duplicated
        """
    )

    duplicate_count = cursor.fetchone()[0]

    if duplicate_count == 0:
        return (
            "PASS",
            "0",
            duplicate_count,
            f"No duplicated {column_name} values found.",
        )

    return (
        "FAIL",
        "0",
        duplicate_count,
        f"Found {duplicate_count} duplicated {column_name} values.",
    )


def check_order_calculations(cursor):
    """
    Validates that order totals are mathematically consistent.

    Expected:
        total_amount =
            subtotal
            + tax_amount
            + shipping_cost
            - discount_amount
    """

    cursor.execute(
        """
        SELECT COUNT(*)
        FROM silver.orders
        WHERE ABS(
            COALESCE(total_amount, 0)
            -
            (
                COALESCE(subtotal, 0)
                + COALESCE(tax_amount, 0)
                + COALESCE(shipping_cost, 0)
                - COALESCE(discount_amount, 0)
            )
        ) > 0.01
        """
    )

    invalid_count = cursor.fetchone()[0]

    if invalid_count == 0:
        return (
            "PASS",
            "0",
            "0",
            "All order totals are mathematically consistent."
        )

    return (
        "FAIL",
        "0",
        str(invalid_count),
        f"{invalid_count} orders have inconsistent total calculations."
    )

def check_product_prices(cursor):
    cursor.execute(
        """
        SELECT COUNT(*)
        FROM silver.products
        WHERE cost_price < 0
           OR sale_price < 0
        """
    )

    invalid_count = cursor.fetchone()[0]

    if invalid_count == 0:
        return (
            "PASS",
            "0",
            invalid_count,
            "No negative product prices found.",
        )

    return (
        "FAIL",
        "0",
        invalid_count,
        f"Found {invalid_count} products with negative prices.",
    )


def check_review_ratings(cursor):
    cursor.execute(
        """
        SELECT COUNT(*)
        FROM silver.reviews
        WHERE rating < 1
           OR rating > 5
        """
    )

    invalid_count = cursor.fetchone()[0]

    if invalid_count == 0:
        return (
            "PASS",
            "0",
            invalid_count,
            "All review ratings are between 1 and 5.",
        )

    return (
        "FAIL",
        "0",
        invalid_count,
        f"Found {invalid_count} reviews with invalid ratings.",
    )


def run_checks():
    print("=" * 70)
    print("DATA QUALITY CHECKS")
    print("=" * 70)
    print(f"Run ID: {RUN_ID}")
    print("=" * 70)

    connection = get_connection()
    cursor = connection.cursor()

    checks_failed = False

    try:

        # =====================================================
        # USERS
        # =====================================================

        status, expected, actual, message = check_table_not_empty(
            cursor,
            "users",
        )

        save_result(
            cursor,
            "silver",
            "users",
            "table_not_empty",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        status, expected, actual, message = check_nulls(
            cursor,
            "users",
            "user_id",
        )

        save_result(
            cursor,
            "silver",
            "users",
            "user_id_not_null",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        status, expected, actual, message = check_duplicates(
            cursor,
            "users",
            "user_id",
        )

        save_result(
            cursor,
            "silver",
            "users",
            "user_id_unique",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        # =====================================================
        # PRODUCTS
        # =====================================================

        status, expected, actual, message = check_table_not_empty(
            cursor,
            "products",
        )

        save_result(
            cursor,
            "silver",
            "products",
            "table_not_empty",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        status, expected, actual, message = check_nulls(
            cursor,
            "products",
            "product_id",
        )

        save_result(
            cursor,
            "silver",
            "products",
            "product_id_not_null",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        status, expected, actual, message = check_duplicates(
            cursor,
            "products",
            "product_id",
        )

        save_result(
            cursor,
            "silver",
            "products",
            "product_id_unique",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        status, expected, actual, message = check_product_prices(
            cursor
        )

        save_result(
            cursor,
            "silver",
            "products",
            "prices_non_negative",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        # =====================================================
        # ORDERS
        # =====================================================

        status, expected, actual, message = check_table_not_empty(
            cursor,
            "orders",
        )

        save_result(
            cursor,
            "silver",
            "orders",
            "table_not_empty",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        status, expected, actual, message = check_nulls(
            cursor,
            "orders",
            "order_id",
        )

        save_result(
            cursor,
            "silver",
            "orders",
            "order_id_not_null",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        status, expected, actual, message = check_duplicates(
            cursor,
            "orders",
            "order_id",
        )

        save_result(
            cursor,
            "silver",
            "orders",
            "order_id_unique",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        status, expected, actual, message = check_order_calculations(
            cursor
        )

        save_result(
            cursor,
            "silver",
            "orders",
            "total_calculation_valid",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        # =====================================================
        # EVENTS
        # =====================================================

        status, expected, actual, message = check_table_not_empty(
            cursor,
            "events",
        )

        save_result(
            cursor,
            "silver",
            "events",
            "table_not_empty",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        status, expected, actual, message = check_nulls(
            cursor,
            "events",
            "event_id",
        )

        save_result(
            cursor,
            "silver",
            "events",
            "event_id_not_null",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        status, expected, actual, message = check_duplicates(
            cursor,
            "events",
            "event_id",
        )

        save_result(
            cursor,
            "silver",
            "events",
            "event_id_unique",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        # =====================================================
        # REVIEWS
        # =====================================================

        status, expected, actual, message = check_table_not_empty(
            cursor,
            "reviews",
        )

        save_result(
            cursor,
            "silver",
            "reviews",
            "table_not_empty",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        status, expected, actual, message = check_nulls(
            cursor,
            "reviews",
            "review_id",
        )

        save_result(
            cursor,
            "silver",
            "reviews",
            "review_id_not_null",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        status, expected, actual, message = check_duplicates(
            cursor,
            "reviews",
            "review_id",
        )

        save_result(
            cursor,
            "silver",
            "reviews",
            "review_id_unique",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        status, expected, actual, message = check_review_ratings(
            cursor
        )

        save_result(
            cursor,
            "silver",
            "reviews",
            "rating_valid",
            status,
            expected,
            actual,
            message,
        )

        if status == "FAIL":
            checks_failed = True

        connection.commit()

        print("=" * 70)

        if checks_failed:
            print("DATA QUALITY FAILED")
            print("=" * 70)
            raise RuntimeError(
                "One or more data quality checks failed."
            )

        print("DATA QUALITY PASSED")
        print("=" * 70)

    except Exception:
        connection.rollback()
        raise

    finally:
        cursor.close()
        connection.close()


if __name__ == "__main__":
    run_checks()