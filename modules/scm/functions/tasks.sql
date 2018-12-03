CREATE OR REPLACE FUNCTION scm.tasks (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      t.task_id AS "taskId",
      t.name,
      p.name AS "productName",
      r.seq_num AS "sequenceNumber"
    FROM scm.task t
    INNER JOIN scm.route_task r
      USING (task_id)
    LEFT JOIN prd.product_list_v p
      USING (product_id)
    WHERE r.route_id = ($1->>'routeId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql';
