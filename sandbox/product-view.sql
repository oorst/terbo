WITH RECURSIVE product AS (
  SELECT
    product_id
  FROM prd.product p

  UNION ALL

  SELECT
    c.component_id AS product_id
  FROM product
  INNER JOIN prd.composition c
    ON product.product_id = c.composite_id
)
SELECT *
FROM product;
