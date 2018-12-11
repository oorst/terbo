CREATE OR REPLACE FUNCTION prj.job (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      j.job_id AS "jobId",
      j.name,
      j.short_desc AS "shortDescription",
      j.status,
      prg.finished_task_count AS "finishedTaskCount",
      prg.total_task_count AS "totalTaskCount",
      floor(prg.finished_task_count::numeric / prg.total_task_count::numeric * 100) AS "percentComplete"
    FROM prj.job j
    -- Calculate job progress
    LEFT JOIN LATERAL (
      SELECT
        j.job_id,
        sum(prg.finished_task_count) AS finished_task_count,
        sum(prg.total_task_count) AS total_task_count
      FROM prj.flatten_job(j.job_id) fj
      INNER JOIN prj.deliverable d
        ON d.job_id = fj.job_id
      INNER JOIN scm.item_progress(d.item_uuid) prg
        ON prg.item_uuid = d.item_uuid
    ) prg ON prg.job_id = j.job_id
    WHERE j.job_id = ($1->>'jobId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
