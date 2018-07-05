/**
Get folderd of a specified parent.
*/

CREATE OR REPLACE FUNCTION folder.get_folders(
  json,
  OUT result json
) AS
$$
DECLARE
  _parent_id  integer;
BEGIN
  IF $1->'parentId' IS NULL THEN
    SELECT json_agg(r) INTO result
    FROM (
      SELECT f.parent AS "parentId", f.data, node_id AS id
      FROM folder.node f
      WHERE f.project_id = _project_id AND f.access != -1
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
