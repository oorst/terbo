CREATE OR REPLACE FUNCTION sales.create_line_item (json, OUT result json) AS
$$
BEGIN
  IF json_typeof($1) = 'array' THEN
    SELECT json_agg(sales.create_line_item(value)) INTO result
    FROM json_array_elements($1);
  ELSE
    WITH payload AS (
      SELECT
        j."orderId" AS order_id,
        j."productId" AS product_id
      FROM json_to_record($1) AS j (
        "orderId"   integer,
        "productId" integer
      )
    ), line_item AS (
      INSERT INTO sales.line_item (
        order_id,
        product_id
      )
      SELECT
        p.order_id,
        p.product_id
      FROM payload p
      RETURNING *
    )
    SELECT json_strip_nulls(to_json(r)) INTO result
    FROM (
      SELECT
        li.line_item_id AS "lineItemId",
        li.order_id AS "orderId",
        li.product_id AS "productId",
        p.code,
        p.name,
        p.short_desc AS "shortDescription"
      FROM line_item li
      LEFT JOIN prd.product_list_v p
        USING (product_id)
    ) r;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

COMMENT ON FUNCTION sales.create_line_item(json) IS 'Terbo provided function.';
