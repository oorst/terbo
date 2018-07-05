CREATE OR REPLACE FUNCTION hucx.get_folders(json, OUT result json) AS
$$
BEGIN
  IF $1->'projectId' IS NULL THEN
    RAISE EXCEPTION 'No projectId property found' USING HINT = 'A projectId property must be provided';
  END IF;

  _project_id = ($1->>'projectId')::integer;

  IF $1->'parentId' IS NULL THEN
    SELECT json_agg(r) INTO result
    FROM (
      SELECT n.parent AS "parentId", n.data, n.node_id AS "nodeId"
      FROM folder.node n
      INNER JOIN hucx.proj_fold pf
      WHERE pf.project_id = ($1->>'projectId')::integer AND n.access != -1
    ) r;
  ELSE
    _parent_id = ($1->>'parentId')::integer;

    SELECT json_agg(r) INTO result
    FROM (
      SELECT f.parent AS "parentId", f.data, node_id AS id
      FROM folder.node f
      WHERE f.project_id = _project_id
        AND (f.parent = _parent_id OR (_parent_id IS NULL AND f.parent IS NULL))
        AND f.access != -1
    ) r;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
