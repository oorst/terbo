CREATE OR REPLACE FUNCTION scm.add_task (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      p."routeId" AS route_id,
      p."taskId" AS task_id
    FROM json_to_record($1) AS p (
      "routeId" integer,
      "taskId"  integer
    )
  ), new_route_task AS (
    INSERT INTO scm.route_task (
      route_id,
      task_id
    )
    SELECT
      *
    FROM payload
    RETURNING *
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      route_id AS "routeId",
      task_id AS "taskId",
      seq_num AS "sequenceNumber"
    FROM new_route_task
  ) r;
END
$$
LANGUAGE 'plpgsql';
