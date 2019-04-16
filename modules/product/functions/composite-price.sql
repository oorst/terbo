/**
 * Return the price of a product.
 * 
 * Since products can be composites or standalone, the price may need to be
 * computed. Recursively select components until one with a price is found and
 * stop.
 * 
 * Use prd.price_v to ensure that a full price record is selected.
 */
CREATE OR REPLACE FUNCTION prd.composite_price (integer, OUT result prd.price_t) AS
$$
BEGIN
  WITH RECURSIVE product AS (
    -- First, select the immediate children of the root product
    SELECT
      c.product_id,
      c.quantity,
      c.parent_id
    FROM prd.component c
    WHERE c.parent_id = $1

    UNION ALL

    -- Recursively select children where the parent does NOT have a price
    SELECT
      c.product_id,
      (p.quantity * c.quantity)::numeric(10,3) AS quantity, -- Adjust quantities
      c.parent_id
    FROM product p
    LEFT JOIN prd.price_v pr
      ON pr.product_id = p.product_id
    INNER JOIN prd.component c
      ON c.parent_id = p.product_id AND pr IS NULL
  ), totals AS (
    SELECT
      $1 AS product_id,
      sum(pr.cost * p.quantity)::numeric(10,2) AS cost,
      sum(pr.gross * p.quantity)::numeric(10,2) AS gross,
      sum(pr.price * p.quantity)::numeric(10,2) AS price
    FROM product p
    LEFT JOIN prd.price(p.product_id) pr
      ON pr.product_id = p.product_id
  )
  SELECT INTO result
    pr.price_id,
    t.product_id,
    CASE
      WHEN pr.cost IS NOT NULL THEN pr.cost
      ELSE t.cost
    END AS cost,
    CASE
      WHEN pr.gross IS NOT NULL THEN pr.gross
      WHEN pr.margin IS NOT NULL THEN
        (t.cost * (1 / pr.margin))::numeric(10,2)
      ELSE t.gross
    END AS gross,
    CASE
      WHEN pr.price IS NOT NULL THEN pr.price
      ELSE t.gross
    END AS price
  FROM totals t
  LEFT JOIN prd.price_v pr
    ON pr.product_id = t.product_id;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;