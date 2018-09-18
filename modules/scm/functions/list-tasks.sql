CREATE OR REPLACE FUNCTION scm.list_tasks (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."routeId" AS route_id
    FROM json_To_record($1) AS j (
      "routeId" integer
    )
  )
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      t.task_id AS "taskId",
      t.name
    FROM scm.task t
    INNER JOIN scm.route_task rt
      USING (task_id)
    INNER JOIN payload
      USING (route_id)
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

CREATE OR REPLACE FUNCTION scm.list_tasks (OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      t.route_id AS "taskId",
      coalesce(t.name, p.name) AS name,
      p.code
    FROM scm.tasks t
    INNER JOIN prd.product_list_v p
      USING (product_id)
    ORDER BY p.name
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
