CREATE OR REPLACE FUNCTION sales.update_line_item (json, OUT result json) AS
$$
BEGIN
  IF json_typeof($1) = 'array' THEN
    SELECT
      json_agg(sales.update_line_item(value)) INTO result
    FROM json_array_elements($1);
  ELSE
    IF $1->'lineItemId' IS NULL THEN
      RAISE EXCEPTION 'id must be provided to a line item';
    END IF;

    EXECUTE (
      SELECT
        format('UPDATE sales.line_item SET (%s) = (%s) WHERE line_item_id = ''%s''', c.column, c.value, c.line_item_id)
      FROM (
        SELECT
          string_agg(q.column, ', ') AS column,
          string_agg(q.value, ', ') AS value,
          ($1->>'lineItemId')::integer AS line_item_id
        FROM (
          SELECT
            CASE p.key
              WHEN 'productId' THEN 'product_id'
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
          WHERE p.key != 'lineItemId' AND p.key IN (
            'position',
            'quantity',
            'gross',
            'productId'
          )
        ) q
      ) c
    );

    SELECT format('{ "lineItemId": %s, "ok": true }', $1->>'lineItemId')::json INTO result;
  END IF;

END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
