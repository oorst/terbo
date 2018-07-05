/*
This is recursive function that calculates the gross price of a composite
product.
*/
CREATE OR REPLACE FUNCTION prd.composite_product_gross (integer, OUT result numeric(10,2)) AS
$$
BEGIN
  IF EXISTS(SELECT FROM prd.composition WHERE composite_id = $1) THEN
    SELECT
      SUM(prd.composite_product_gross(composition.component_id) * composition.quantity)::numeric(10,2) INTO result
    FROM prd.composition composition
    INNER JOIN prd.product_pricing_v p
      ON p.product_id = composition.component_id
    WHERE composition.composite_id = $1;
  ELSE
    SELECT
      COALESCE(p.gross, 0.00) INTO result
    FROM prd.product_pricing_v p
    WHERE p.product_id = $1;
  END IF;
END
$$
LANGUAGE 'plpgsql';
