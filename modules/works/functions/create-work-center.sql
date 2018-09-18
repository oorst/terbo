CREATE OR REPLACE FUNCTION works.create_work_center (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j.name,
      j."userId" AS created_by
    FROM json_to_record($1) AS j (
      name     text,
      "userId" integer
    )
  ), work_center AS (
    INSERT INTO works.work_center (
      name
    )
    SELECT
      p.name
    FROM payload p
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      w.work_center_id AS "workCenterId",
      w.name
    FROM work_center w
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
