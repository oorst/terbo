CREATE OR REPLACE FUNCTION prd.flatten_product (integer)
RETURNS TABLE (
  product_id   integer,
  component_id integer,
  quantity     numeric(10,3),
  parent_id    integer,
  is_composite boolean
) AS
$$
BEGIN
  RETURN QUERY
  WITH RECURSIVE product AS (
    SELECT
      p.product_id,
      NULL::integer AS component_id,
      1::numeric(10,3) AS quantity,
      NULL::integer AS parent_id,
      EXISTS(SELECT FROM prd.component c WHERE c.parent_id = p.product_id) AS is_composite
    FROM prd.product p
    WHERE p.product_id = $1

    UNION ALL

    SELECT
      p.product_id,
      c.component_id,
      c.quantity,
      product.product_id AS parent_id,
      EXISTS(SELECT FROM prd.component c WHERE c.parent_id = p.product_id) AS is_composite
    FROM product
    INNER JOIN prd.component c
      ON c.parent_id = product.product_id
    LEFT JOIN prd.product p
      ON p.product_id = c.product_id
  )
  SELECT * FROM product;
END
$$
LANGUAGE 'plpgsql';
