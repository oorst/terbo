CREATE OR REPLACE FUNCTION sales.create_line_item (json, OUT result json) AS
$$
DECLARE
  new_line_item_uuid uuid;
BEGIN
  IF json_typeof($1) = 'array' THEN
    SELECT json_agg(sales.create_line_item(value)) INTO result
    FROM json_array_elements($1);
  ELSE
    INSERT INTO sales.line_item (
      order_uuid,
      product_uuid,
      short_desc,
      quantity
    )
    SELECT
      p.*
    FROM json_to_record($1) AS p (
      order_uuid   uuid,
      product_uuid uuid,
      short_desc   text,
      quantity     numeric(10,3)
    )
    RETURNING line_item_uuid INTO new_line_item_uuid;
    
    SELECT json_strip_nulls(to_json(r)) INTO result
    FROM sales.line_item(new_line_item_uuid) r;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
