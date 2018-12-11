/**
Return tasks in the queue that are ready. Do not return tasks where the
corresponding Item's children's tasks have not been finished.
*/

CREATE OR REPLACE FUNCTION scm.task_queue (json, OUT result json) AS
$$
BEGIN
  WITH task_queue AS (
    SELECT
      q.*,
      c.parent_uuid
    FROM scm.task_queue_v q
    LEFT JOIN scm.component c
      ON c.item_uuid = q.item_uuid
    WHERE q.finished_at IS NULL
  )
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      q.task_id AS "taskId",
      q.item_uuid AS "itemUuid",
      q.work_center_id AS "workCenterId",
      q.route_id AS "routeId",
      q.seq_num AS "sequenceNumber",
      q.batch_uuid AS "batchUuid",
      i.name AS "itemName",
      coalesce(t.name, p.name) AS "taskName",
      pth.name_path AS "namePath",
      pth.item_uuid_path AS "itemUuidPath"
    FROM task_queue q
    LEFT JOIN scm.path(q.item_uuid) pth
      ON pth.item_uuid = q.item_uuid
    LEFT JOIN scm.item_list_v i
      ON i.item_uuid = q.item_uuid
    INNER JOIN scm.task t
      USING (task_id)
    INNER JOIN prd.product_list_v p
      ON p.product_id = t.product_id
    WHERE q.work_center_id = ($1->>'workCenterId')::integer
      AND q.item_uuid NOT IN (
        SELECT
          parent_uuid
        FROM task_queue
        WHERE parent_uuid IS NOT NULL
      )
    ORDER BY q.batch_priority, q.sorting_num
  ) r;
END
$$
LANGUAGE 'plpgsql';
