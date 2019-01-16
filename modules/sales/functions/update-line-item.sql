CREATE OR REPLACE FUNCTION sales.update_line_item (json, OUT result json) AS
$$
BEGIN
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
            WHEN 'grossLineTotal' THEN 'gross_line_total'
            WHEN 'netLineTotal' THEN 'net_line_total'
            WHEN 'shortDescription' THEN 'short_desc'
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
        WHERE p.key != 'lineItemId'
      ) q
    ) c
  );

  SELECT format('{ "lineItemId": %s, "ok": true }', $1->>'lineItemId')::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

-- Update modified column automatically and update parents
CREATE OR REPLACE FUNCTION sales.update_line_item_tg () RETURNS TRIGGER AS
$$
BEGIN
  SELECT CURRENT_TIMESTAMP INTO NEW.modified;

  -- Update the Order the line item belongs to
  UPDATE sales.order o SET (
    modified
  ) = (
    CURRENT_TIMESTAMP
  )
  WHERE o.order_id = NEW.order_id;

  RETURN NEW;
END
$$
LANGUAGE 'plpgsql';
