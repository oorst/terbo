/**
Get the children of the given node
*/
CREATE OR REPLACE FUNCTION folder._get_children (integer, OUT result json) AS
$$
BEGIN
  SELECT json_agg(r) INTO result
  FROM (
    SELECT node_id AS "nodeId",
      data
    FROM folder.node n
    WHERE n.parent = $1
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION folder.get_children (json, OUT result json) AS
$$
BEGIN
  SELECT folder._get_children(($1->>'parentId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
