-- =========================================================
-- MONITORING
-- TABLE: monitoring.data_quality_results
-- DESCRIPTION:
-- Stores the results of automated data quality checks.
-- =========================================================

CREATE TABLE IF NOT EXISTS monitoring.data_quality_results (

    quality_check_id BIGSERIAL PRIMARY KEY,

    run_id UUID NOT NULL,

    table_schema TEXT NOT NULL,

    table_name TEXT NOT NULL,

    check_name TEXT NOT NULL,

    status TEXT NOT NULL
        CHECK (status IN ('PASS', 'FAIL', 'WARN')),

    expected_value TEXT,

    actual_value TEXT,

    message TEXT,

    checked_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

);

CREATE INDEX IF NOT EXISTS idx_dq_results_run_id
    ON monitoring.data_quality_results(run_id);

CREATE INDEX IF NOT EXISTS idx_dq_results_table
    ON monitoring.data_quality_results(table_schema, table_name);

CREATE INDEX IF NOT EXISTS idx_dq_results_status
    ON monitoring.data_quality_results(status);

CREATE INDEX IF NOT EXISTS idx_dq_results_checked_at
    ON monitoring.data_quality_results(checked_at);