CREATE OR REPLACE FUNCTION scm.update_route (json, OUT result json) AS
$$
BEGIN
  WITH existing AS (
    SELECT *
    FROM scm.route
    WHERE route_id = ($1->>'id')::integer
  )
  UPDATE scm.route rt
  SET (
    name,
    data,
    modified
  ) = (
    CASE
      WHEN $1->'name' IS NULL THEN -- Note use of single bracket selector
        x.name
      ELSE $1->>'name'
    END,
    CASE
      WHEN $1->'data' IS NULL THEN
        x.data
      ELSE ($1->'data')::jsonb
    END,
    -- modified
    CURRENT_TIMESTAMP
  )
  FROM existing x
  WHERE rt.route_id = x.route_id;

  WITH task AS (
    SELECT
      t.id,
      t."seqNum"
    FROM json_to_recordset($1->'tasks') AS
      t (
        id       integer,
        "seqNum" integer,
        rtid     integer
      )
    WHERE t.rtid IS NULL -- No rtid means this is a new task
  )
  INSERT INTO scm.route_task (
    route_id,
    task_id,
    seq_num
  )
  SELECT
    ($1->>'id')::integer,
    id,
    "seqNum"
  FROM task;

  -- Delete removed Tasks
  WITH task AS (
    SELECT
      t.id
    FROM json_to_recordset($1->'tasks') AS
      t (
        id integer,
        removed boolean
      )
    WHERE t.removed IS TRUE
  )
  DELETE FROM scm.route_task rt
  USING task
  WHERE rt.task_id = task.id;

  SELECT scm.get_route(($1->>'id')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
