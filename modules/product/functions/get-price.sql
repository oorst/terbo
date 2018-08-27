CREATE OR REPLACE FUNCTION prd.get_price (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT DISTINCT ON (p.product_id)
      price_id AS "priceId",
      product_id AS "productId",
      cost,
      gross,
      net,
      margin,
      margin_id AS "marginId",
      markup,
      markup_id AS "markupId",
      tax,
      created
    FROM prd.price p
    WHERE p.product_id = ($1->>'productId')::integer
    ORDER BY p.product_id, p.price_id DESC
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
