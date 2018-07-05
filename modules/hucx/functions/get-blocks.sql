CREATE OR REPLACE FUNCTION hucx.get_blocks (json, OUT result json) AS
$$
BEGIN
  IF $1->>'projectId' IS NOT NULL THEN
    SELECT json_agg(r) INTO result
    FROM (
      SELECT b.block_id AS "blockId", b.data
      FROM hucx.block b
      INNER JOIN hucx.element e ON b.element_id = e.element_id
      WHERE e.project_id = ($1->>'projectId')::integer
    ) r;
  ELSIF $1->>'elementId' IS NOT NULL THEN
    SELECT json_agg(r) INTO result
    FROM (
      SELECT b.block_id AS "id", b.element_id AS "elementId", b.data
      FROM hucx.block b
      WHERE b.element_id = ($1->>'elementId')::integer
    ) r;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
