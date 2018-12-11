CREATE OR REPLACE FUNCTION scm.finish_task (json, OUT result json) AS
$$
BEGIN
  UPDATE scm.task_item ti
  SET finished_at = CURRENT_TIMESTAMP
  WHERE ti.item_uuid = ($1->>'itemUuid')::uuid
    AND ti.task_id = ($1->>'taskId')::integer;

  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      ti.finished_at AS "finishedAt",
      TRUE AS ok
    FROM scm.task_item ti
    WHERE ti.item_uuid = ($1->>'itemUuid')::uuid
  ) r;
END
$$
LANGUAGE 'plpgsql';
