CREATE OR REPLACE FUNCTION prd.update_component (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE prd.component SET (%s) = (%s) WHERE component_id = ''%s''', c.column, c.value, c.component_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'componentId')::integer AS component_id
      FROM (
        SELECT
          CASE p.key
            WHEN 'productId' THEN 'product_id'
            WHEN 'uomId' THEN 'uom_id'
            ELSE p.key
          END AS column,
          CASE
            -- check if it's a number
            WHEN p.value ~ '^\d+(.\d+)?$' THEN
              p.value
            WHEN p.value IS NULL THEN
              'NULL'
            ELSE quote_literal(p.value)
          END AS value
        FROM json_each_text($1) p
        WHERE p.key != 'componentId' -- Don't include the id
      ) q
    ) c
  );

  SELECT '{ "ok": true }'::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
