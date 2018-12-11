CREATE OR REPLACE FUNCTION prj.copy_deliverable (json, OUT result json) AS
$$
BEGIN
  WITH new_deliverable AS (
    INSERT INTO prj.deliverable (
      job_id,
      item_uuid,
      lag,
      lead,
      created
    )
    SELECT
      d.job_id,
      scm.copy_item(d.item_uuid),
      d.lag,
      d.lead,
      CURRENT_TIMESTAMP
    FROM prj.deliverable d
    WHERE d.deliverable_id = ($1->>'deliverableId')::integer
    RETURNING *
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      deliverable_id AS "deliverableId"
    FROM new_deliverable
  ) r;
END
$$
LANGUAGE 'plpgsql';
