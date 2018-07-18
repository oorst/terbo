CREATE OR REPLACE FUNCTION prd.composite_product_gross (integer, OUT result numeric(10,2)) AS
$$
BEGIN
  WITH RECURSIVE component AS (
    SELECT
      p.product_id,
      c.quantity,
      CASE WHEN p.composition_id IS NULL THEN FALSE
      ELSE TRUE END AS isComposite
    FROM prd.component c
    INNER JOIN prd.product p
      USING (product_id)
    WHERE c.parent_id = $1

    UNION ALL

    SELECT
      p.product_id,
      (component.quantity * c.quantity)::numeric(10,3) AS quantity,
      CASE WHEN p.composition_id IS NULL THEN TRUE
      ELSE NULL END AS isComposite
    FROM prd.component c
    INNER JOIN prd.product p
      USING (product_id)
    INNER JOIN component
      ON component.product_id = c.parent_id
  )
  SELECT
    sum(coalesce(price.gross, cost.amount * (1 + price.markup / 100.00)))::numeric(10,2) INTO result
  FROM component
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
  WHERE component.isComposite IS FALSE;
END
$$
LANGUAGE 'plpgsql';
