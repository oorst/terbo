CREATE OR REPLACE FUNCTION prj.get_boqs (json, OUT result json) AS
$$
BEGIN
  IF $1->>'jobId' IS NULL THEN
    RAISE EXCEPTION 'jobId not provided';
  END IF;

  WITH RECURSIVE boq AS (
    SELECT
      j.job_id,
      j.name
    FROM prj.job j
    WHERE j.job_id = ($1->>'jobId')::integer

    UNION ALL

    SELECT
      j.job_id,
      j.name
    FROM job
    INNER JOIN prj.job j
      ON j.prerequisite_id = job.job_id
  )
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      j.job_id AS "jobId",
      j.name
    FROM job j
    INNER JOIN prj.boq_line_item li
      USING (job_id)
  ) r;
END
$$
LANGUAGE 'plpgsql';
