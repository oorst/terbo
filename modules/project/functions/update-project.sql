/*
Create a dyamic query that only updates fileds that present on the payload
*/
CREATE OR REPLACE FUNCTION prj.update_project (json, OUT result json) AS
$$
BEGIN
  IF $1->'projectId' IS NULL THEN
    RAISE EXCEPTION 'projectId not provided';
  END IF;

  EXECUTE (
    SELECT
      format('UPDATE prj.project SET (%s) = (%s) WHERE project_id = ''%s''', c.column, c.value, c.project_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'projectId')::integer AS project_id
      FROM (
        SELECT
          p.key AS column,
          -- CASE p.key
          --   WHEN 'productId' THEN 'product_id'
          --   ELSE p.key
          -- END AS column,
          CASE
            -- check if it's a number
            WHEN p.value ~ '^\d+(.\d+)?$' THEN
              p.value
            WHEN p.value IS NULL THEN
              'NULL'
            ELSE quote_literal(p.value)
          END AS value
        FROM json_each_text($1) p
        WHERE p.key != 'projectId'
      ) q
    ) c
  );

  SELECT '{ "ok": true }'::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
