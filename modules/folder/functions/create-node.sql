CREATE OR REPLACE FUNCTION folder.create_node (json, OUT result json) AS
$$
DECLARE
  existing    RECORD;
  _project_id integer;
  _parent     integer;
  _data       jsonb;
BEGIN
  SELECT * INTO existing
  FROM folder.node folder
  WHERE lower(folder.data->>'name') = lower($1#>>'{data,name}') AND (folder.parent = ($1->>'parentId')::integer OR (($1->>'parentId') IS NULL AND folder.parent IS NULL));

  IF existing.node_id IS NOT NULL AND existing.access != -1 THEN
    result = '{"error": { "message": "Name already exists"} }'::json;
    RETURN;
  END IF;

  _project_id = ($1->>'projectId')::integer;
  _parent = ($1->>'parentId')::integer;
  _data = ($1->>'data')::jsonb;

  WITH new_folder AS (
    INSERT INTO folder.node (project_id, parent, data)
    VALUES (_project_id, _parent, _data) RETURNING *
  ) SELECT to_json(folder) INTO result
  FROM (SELECT f.parent AS "parentId", data, node_id AS id FROM new_folder f) folder;

  -- Parent folder modified timestamp update
  UPDATE folder.node
  SET modified = CURRENT_TIMESTAMP
  WHERE node_id = _parent;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
