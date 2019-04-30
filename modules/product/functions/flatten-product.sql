/**
Flatten Product

Flatten a potentially composite product into a set of records.

Adjust the quantity where a secondary uom is given for the root uom
*/

CREATE OR REPLACE FUNCTION prd.flatten_product (
  _product_id  integer,
  _root_uom_id integer DEFAULT NULL
) RETURNS TABLE (
  root_id    integer,
  product_id integer,
  parent_id  integer,
  uom_id     integer,
  quantity   numeric(10,3),
  is_leaf    boolean
) AS
$$
BEGIN
  RETURN QUERY
  WITH RECURSIVE product AS (
    SELECT
      NULL::integer AS parent_id,
      _product_id AS product_id,
      _root_uom_id AS uom_id,
      1::numeric(10,3) AS quantity

    UNION ALL

    SELECT
      p.product_id AS parent_id,
      c.product_id,
      c.uom_id,
      (p.quantity * c.quantity)::numeric(10,3) AS quantity
    FROM product p
    INNER JOIN prd.component c
      ON c.parent_id = p.product_id
  )
  SELECT
    $1 AS root_id,
    p.product_id,
    p.parent_id,
    p.uom_id,
    (p.quantity * coalesce(uom.multiplier, 1.000))::numeric(10,3) AS quantity,
    CASE
      WHEN p.product_id IN (SELECT q.parent_id FROM product q) THEN FALSE
      ELSE TRUE
    END
  FROM product p
  LEFT JOIN (
    SELECT
      (coalesce(u.multiply, 1.000) / coalesce(u.divide, 1.000))::numeric(8,3) AS multiplier
    FROM prd.product_uom u
    WHERE u.product_id = _product_id
      AND u.uom_id = _root_uom_id
  ) uom ON p.product_id IS DISTINCT FROM _product_id;
END
$$
LANGUAGE 'plpgsql';
