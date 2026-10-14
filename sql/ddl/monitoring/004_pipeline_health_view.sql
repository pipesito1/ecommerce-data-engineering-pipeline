CREATE OR REPLACE VIEW monitoring.v_pipeline_health AS
SELECT
    pr.pipeline_run_id,
    pr.dag_id,
    pr.status AS pipeline_status,
    pr.started_at AS pipeline_started_at,
    pr.finished_at AS pipeline_finished_at,
    pr.duration_seconds AS pipeline_duration_seconds,

    ptr.task_id,
    ptr.status AS task_status,
    ptr.started_at AS task_started_at,
    ptr.finished_at AS task_finished_at,
    ptr.duration_seconds AS task_duration_seconds,
    ptr.rows_processed,
    ptr.error_message

FROM monitoring.pipeline_runs pr
LEFT JOIN monitoring.pipeline_task_runs ptr
    ON pr.pipeline_run_id = ptr.pipeline_run_id;