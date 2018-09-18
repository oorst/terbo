CREATE OR REPLACE FUNCTION works.work_center (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      w.work_center_id AS "workCenterId",
      w.name,
      w.short_desc AS "shortDescription",
      w.description,
      w.default_instructions AS "defaultInstructions",
      w.created,
      w.modified
    FROM works.work_center w
    WHERE w.work_center_id = ($1->>'workCenterId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
