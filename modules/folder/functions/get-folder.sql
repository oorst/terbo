CREATE OR REPLACE FUNCTION folder.get_folder(json, OUT result json) AS
$$
BEGIN
  SELECT to_json(r) INTO result
  FROM (
    SELECT node_id AS "nodeId",
      data
    FROM folder.node n
    WHERE n.node_id = ($1->>'nodeId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
