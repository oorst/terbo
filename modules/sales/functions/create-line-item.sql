CREATE OR REPLACE FUNCTION sales.create_line_item (json, OUT result json) AS
$$
BEGIN
  IF json_typeof($1) = 'array' THEN
    SELECT json_agg(sales.create_line_item(value)) INTO result
    FROM json_array_elements($1);
  ELSE
    WITH payload AS (
      SELECT
        j.*
      FROM json_to_record($1) AS j (
        order_id   integer,
        product_id integer,
        short_desc text
      )
    ), line_item AS (
      INSERT INTO sales.line_item (
        order_id,
        product_id,
        short_desc
      )
      SELECT
        p.order_id,
        p.product_id,
        p.short_desc
      FROM payload p
      RETURNING *
    )
    SELECT json_strip_nulls(to_json(r)) INTO result
    FROM (
      SELECT
        li.line_item_id,
        li.order_id,
        li.product_id,
        li.short_desc
      FROM line_item li
    ) r;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

COMMENT ON FUNCTION sales.create_line_item(json) IS 'Terbo provided function.';
