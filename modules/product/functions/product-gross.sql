CREATE OR REPLACE FUNCTION prd.product_gross (integer, OUT result numeric(10,2)) AS
$$
BEGIN
  WITH RECURSIVE product AS (
    SELECT
      p.product_id,
      1::numeric(10,3) AS quantity,
      EXISTS(SELECT FROM prd.component c WHERE c.parent_id = p.product_id) AS is_composite
    FROM prd.product p
    WHERE p.product_id = $1

    UNION ALL

    SELECT
      c.product_id,
      (p.quantity * c.quantity)::numeric(10,3) AS quantity,
      EXISTS(SELECT FROM prd.component c WHERE c.parent_id = c.product_id) AS is_composite
    FROM product p
    INNER JOIN prd.component c
      ON c.parent_id = p.product_id
  )
  SELECT
    sum(coalesce(price.gross, cost.amount * (1 + price.markup / 100.00)) * product.quantity)::numeric(10,2) INTO result
  FROM product
  LEFT JOIN (
    SELECT DISTINCT ON (cost.product_id)
      cost.product_id,
      cost.cost_id,
      cost.amount
    FROM prd.cost cost
    WHERE cost.end_at > CURRENT_TIMESTAMP OR cost.end_at IS NULL
    ORDER BY cost.product_id, cost.cost_id DESC
  ) cost
    USING (product_id)
  LEFT JOIN (
    SELECT DISTINCT ON (price.product_id)
      price.product_id,
      price.price_id,
      price.gross,
      price.net,
      COALESCE(price.markup, markup.amount, 0.00) AS markup
    FROM prd.price price
    LEFT JOIN prd.markup
      USING (markup_id)
    ORDER BY price.product_id, price.price_id DESC
  ) price
    USING (product_id)
  WHERE product.is_composite IS FALSE;
END
$$
LANGUAGE 'plpgsql';
