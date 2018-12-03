CREATE OR REPLACE FUNCTION prj.jobs (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      j.job_id AS "jobId",
      j.name,
      j.short_desc AS "shortDescription",
      j.seq_num AS "sequenceNumber"
    FROM prj.job j
    WHERE j.dependant_id = ($1->>'jobId')::integer
    ORDER BY j.seq_num
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
