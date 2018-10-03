CREATE OR REPLACE FUNCTION sales.create_line_item (json, OUT result json) AS
$$
BEGIN
  IF json_typeof($1) = 'array' THEN
    SELECT json_agg(sales.create_line_item(value)) INTO result
    FROM json_array_elements($1);
  ELSE
    IF $1->>'orderId' IS NULL THEN
      RAISE EXCEPTION 'orderId not provided';
    END IF;

    WITH payload AS (
      SELECT
        j."orderId" AS order_id,
        j."productId" AS product_id,
        name,
        code,
        description,
        data,
        quantity,
        gross
      FROM json_to_record($1) AS j (
        "orderId"   integer,
        "productId" integer,
        name        text,
        code        text,
        description text,
        data        jsonb,
        quantity    numeric(10,3),
        gross       numeric(10,2)
      )
    ), line_item AS (
      INSERT INTO sales.line_item (
        order_id,
        product_id,
        code,
        name,
        description,
        data,
        quantity,
        gross
      )
      SELECT
        p.order_id,
        p.product_id,
        p.code,
        p.name,
        p.description,
        p.data,
        p.quantity,
        p.gross
      FROM payload p
      RETURNING *
    )
    SELECT json_strip_nulls(to_json(r)) INTO result
    FROM (
      SELECT
        line_item_id AS "lineItemId",
        order_id AS "orderId",
        product_id AS "productId",
        code,
        name,
        description,
        data,
        quantity,
        gross
      FROM line_item
    ) r;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

COMMENT ON FUNCTION sales.create_line_item(json) IS 'Terbo provided function.';
