CREATE OR REPLACE FUNCTION scm.create_task (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."routeId" AS route_id,
      j."productId" AS product_id,
      j.name,
      j."userId" AS created_by
    FROM json_to_record($1) AS j (
      "routeId"   integer,
      "productId" integer,
      name        text,
      "userId"    integer
    )
  ), new_task AS (
    INSERT INTO scm.task (
      product_id,
      name
    )
    SELECT
      p.product_id,
      p.name
    FROM payload p
    RETURNING *
  ), route_task AS (
    INSERT INTO scm.route_task (
      route_id,
      task_id
    )
    SELECT
      p.route_id,
      (SELECT task_id FROM new_task)
    FROM payload p
    WHERE p.routeId IS NOT NULL
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      t.task_id AS "taskId",
      t.name
    FROM new_task t
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
