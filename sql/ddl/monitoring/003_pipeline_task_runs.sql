CREATE TABLE IF NOT EXISTS monitoring.pipeline_task_runs (
    task_run_id BIGSERIAL PRIMARY KEY,

    pipeline_run_id UUID NOT NULL
        REFERENCES monitoring.pipeline_runs(pipeline_run_id),

    dag_id TEXT NOT NULL,
    task_id TEXT NOT NULL,

    status TEXT NOT NULL
        CHECK (status IN ('RUNNING', 'SUCCESS', 'FAILED')),

    started_at TIMESTAMPTZ NOT NULL,
    finished_at TIMESTAMPTZ,

    duration_seconds NUMERIC(12, 3),

    rows_processed BIGINT,

    error_message TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_pipeline_task_runs_pipeline
    ON monitoring.pipeline_task_runs(pipeline_run_id);

CREATE INDEX IF NOT EXISTS idx_pipeline_task_runs_task
    ON monitoring.pipeline_task_runs(task_id);

CREATE INDEX IF NOT EXISTS idx_pipeline_task_runs_status
    ON monitoring.pipeline_task_runs(status);

CREATE INDEX IF NOT EXISTS idx_pipeline_task_runs_started_at
    ON monitoring.pipeline_task_runs(started_at);