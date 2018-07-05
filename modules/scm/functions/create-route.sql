CREATE OR REPLACE FUNCTION scm.create_route (json, OUT result json) AS
$$
BEGIN
  WITH new_route AS (
    INSERT INTO scm.route (
      name,
      data
    ) VALUES (
      $1->>'name',
      $1->'data'
    )
    RETURNING *
  ), route_task AS (
    INSERT INTO scm.route_task (
      route_id,
      task_id,
      seq_num
    )
    SELECT
      (SELECT route_id FROM new_route),
      t.id,
      t."seqNum"
    FROM json_to_recordset($1->'tasks') AS t (id integer, "seqNum" integer)
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      rt.route_id AS id,
      rt.name
    FROM new_route rt
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
