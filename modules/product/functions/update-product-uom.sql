CREATE OR REPLACE FUNCTION prd.update_product_uom (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format(
        CASE
          WHEN c.column IS NOT NULL THEN
           'UPDATE prd.product_uom SET (%s) = (%s) WHERE product_uom_id = ''%s'''
          ELSE ''
        END,
        c.column,
        c.value,
        c.product_uom_id
      )
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
        -- Don't include the id
        -- Also don't include any properties that are specific to pricing as
        -- they will form part of a new price record that is inserted later
        WHERE p.key NOT IN (
          'productUomId',
          'cost',
          'gross',
          'margin',
          'marginId',
          'markup',
          'markupId',
          'taxExcluded'
        )
      ) q
    ) c
  );

  -- A pricing history must be kept, so new pricing data simply creates a new
  -- price record
  PERFORM prd.create_price($1);

  SELECT format('{ "ok": true, "productUomId": %s }', ($1->>'productUomId'))::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
