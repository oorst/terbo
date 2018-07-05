/**
This function doesn't really delete nodes, it just marks them for deletion by
setting the access field to -1.  This shows that they are no longer needed.
When the garbage collector comes, nodes marked for deletion will also have any
files they reference removed from storage.
*/
CREATE OR REPLACE FUNCTION folder.delete_node(
  json, -- Force delete even if the node is not empty
  OUT result json
) AS
$$
DECLARE
  children integer;
  _node_id integer;
  deleted RECORD;
BEGIN
  IF $1->'id' IS NULL THEN
    RAISE EXCEPTION 'No id property found';
  END IF;

  _node_id = ($1->>'id')::integer;

  SELECT COUNT(*) INTO children
  FROM folder.node folder
  WHERE folder.parent = _node_id;

  IF children > 0 AND $1->'force' IS NULL THEN
    result = '{"error":{"message":"Folder is not empty"}}'::json;
    RETURN;
  ELSE
    WITH RECURSIVE branch (node_id, parent) AS (
      SELECT f.node_id, f.parent
      FROM folder.node f
      WHERE f.node_id = _node_id

      UNION ALL

      SELECT f.node_id, f.parent
      FROM folder.node f
      INNER JOIN branch b ON f.parent = b.node_id
    ), deleted AS (UPDATE folder.node f
    SET access = -1
    WHERE f.node_id IN (SELECT node_id FROM branch)
    RETURNING *)
    SELECT to_json(d) INTO result FROM (SELECT array_agg(node_id) AS "deletedIds" FROM deleted) d;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
