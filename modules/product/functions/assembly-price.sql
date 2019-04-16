/**
 * Return the price of a product.
 *
 * Since products can be composites or standalone, the price may need to be
 * computed. Recursively select components until one with a price is found and
 * stop.
 *
 * Use prd.price_v to ensure that a full price record is selected.
 */
CREATE OR REPLACE FUNCTION prd.assembly_price (integer, OUT result prd.price_t) AS
$$
BEGIN
  WITH RECURSIVE part AS (
    -- Select the root part
    SELECT
      p.part_uuid,
      p.parent_uuid,
      p.product_id,
      (1.000)::numeric(10,3) AS quantity
    FROM prd.part p
    WHERE p.product_id = $1 AND p.parent_uuid IS NULL
    
    UNION ALL
    
    SELECT
      p.part_uuid,
      p.parent_uuid,
      p.product_id,
      (part.quantity * p.quantity)::numeric(10,3) AS quantity
    FROM part
    INNER JOIN prd.part p ON p.parent_uuid = part.part_uuid
  ),
    leaf AS
  (
    SELECT
      *
    FROM part p
    WHERE p.part_uuid NOT IN (
      SELECT
        parent_uuid
      FROM part
      WHERE parent_uuid IS NOT NULL
    )
  ),
    aggregate AS
  (
    SELECT
      product_id,
      sum(quantity) AS quantity
    FROM leaf
    GROUP BY product_id
  ),
    price AS
  (
    SELECT
      sum(pr.cost * quantity)::numeric(10,2) AS cost,
      sum(pr.gross * quantity)::numeric(10,2) AS gross,
      sum(pr.price * quantity)::numeric(10,2) AS price
    FROM aggregate ag
    LEFT JOIN prd.price(ag.product_id) pr ON pr.product_id = ag.product_id
  )
  SELECT INTO result
    NULL,
    $1,
    p.cost,
    p.gross,
    p.price
  FROM price p;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;