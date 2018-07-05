CREATE OR REPLACE FUNCTION hucx.get_elements (json, OUT result json) AS
$$
BEGIN
  IF $1->>'projectId' IS NOT NULL THEN
    SELECT json_agg(r) INTO result
    FROM (
      SELECT e.element_id AS "id",
        e.data,
        (
          SELECT SUM((b.data->>'price')::numeric(5,2))
          FROM hucx.block b
          WHERE b.element_id = e.element_id
        ) AS "price"
      FROM hucx.element e
      WHERE e.project_id = ($1->>'projectId')::integer
    ) r;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
