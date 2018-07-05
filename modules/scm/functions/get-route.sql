CREATE OR REPLACE FUNCTION scm.get_route (integer, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      route.route_id AS id,
      route.name,
      route.data,
      (
        SELECT json_agg(r)
        FROM (
          SELECT
             -- Use rtid to flag task as current member of route
            rt.route_task_id AS rtid,
            task.task_id AS id,
            COALESCE(task.name, p.name) AS name,
            rt.seq_num AS "seqNum"
          FROM scm.route_task rt
          INNER JOIN scm.task task
            USING (task_id)
          INNER JOIN prd.product p
            USING (product_id)
          WHERE rt.route_id = route.route_id
        ) r
      ) AS tasks
    FROM scm.route route
    WHERE route.route_id = $1
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION scm.get_route (json, OUT result json) AS
$$
BEGIN
  SELECT scm.get_route(($1->>'id')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
