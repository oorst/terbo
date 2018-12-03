CREATE OR REPLACE FUNCTION prj.create_deliverable (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      p."userId" AS created_by,
      p."jobId" AS job_id,
      p.name
    FROM json_to_record($1) AS p (
      "userId"    integer,
      "jobId"     integer,
      name        text
    )
  ), item AS (
    INSERT INTO scm.item (
      name
    )
    SELECT
      p.name
    FROM payload p
    RETURNING item_uuid
  ), deliverable AS (
    INSERT INTO prj.deliverable (
      job_id,
      item_uuid
    )
    SELECT
      p.job_id,
      (SELECT item_uuid FROM item)
    FROM payload p
    RETURNING deliverable_id
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      d.deliverable_id AS "deliverableId"
    FROM deliverable d
  ) r;
END
$$
LANGUAGE 'plpgsql';
