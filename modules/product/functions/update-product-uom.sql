CREATE OR REPLACE FUNCTION prd.update_product_uom (json, OUT result json) AS
$$
BEGIN
  IF $1->'productUomId' IS NULL THEN
    RAISE EXCEPTION 'an id is required to update a component';
  END IF;

  EXECUTE (
    SELECT
      format('UPDATE prd.product_uom SET (%s) = (%s) WHERE product_uom_id = ''%s''', c.column, c.value, c.product_uom_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'productUomId')::integer AS product_uom_id
      FROM (
        SELECT
          CASE p.key
            WHEN 'productUomId' THEN 'product_uom_id'
            WHEN 'roundingRule' THEN 'rounding_rule'
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
        WHERE p.key != 'productUomId' -- Don't include the id
      ) q
    ) c
  );

  SELECT '{ "ok": true }'::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
