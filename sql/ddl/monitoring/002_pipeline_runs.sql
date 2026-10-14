CREATE TABLE IF NOT EXISTS monitoring.pipeline_runs (
    pipeline_run_id UUID PRIMARY KEY,
    dag_id TEXT NOT NULL,
    status TEXT NOT NULL
        CHECK (status IN ('RUNNING', 'SUCCESS', 'FAILED')),

    started_at TIMESTAMPTZ NOT NULL,
    finished_at TIMESTAMPTZ,

    duration_seconds NUMERIC(12, 3),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_pipeline_runs_dag_id
    ON monitoring.pipeline_runs(dag_id);

CREATE INDEX IF NOT EXISTS idx_pipeline_runs_status
    ON monitoring.pipeline_runs(status);

CREATE INDEX IF NOT EXISTS idx_pipeline_runs_started_at
    ON monitoring.pipeline_runs(started_at);