/**
 * Return the price of a product.
 * 
 * Since products can be composites or standalone, the price may need to be
 * computed. Recursively select components until one with a price is found and
 * stop.
 * 
 * Use prd.price_v to ensure that a full price record is selected.
 */
CREATE TYPE prd.price_t AS (
  price_id       integer,
  product_id     integer,
  cost           numeric(10,2),
  gross          numeric(10,2),
  price          numeric(10,2)
);

CREATE OR REPLACE FUNCTION prd.price (integer, OUT result prd.price_t) AS
$$
DECLARE
  product RECORD;
BEGIN
  SELECT * INTO product FROM prd.product_v p WHERE p.product_id = $1;
  
  IF product.is_composite IS TRUE THEN
    SELECT * INTO result FROM prd.composite_price($1);
  ELSIF product.is_assembly IS TRUE THEN
    SELECT * INTO result FROM prd.assembly_price($1);
  ELSE
    SELECT INTO result
      p.price_id,
      p.product_id,
      p.cost,
      p.gross,
      p.price
    FROM prd.price_v p
    WHERE p.product_id = $1;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
