CREATE OR REPLACE FUNCTION scm.price(uuid) RETURNS TABLE (
  item_uuid uuid,
  gross     numeric(10,2),
  cost      numeric(10,2),
  profit    numeric(10,2),
  margin    numeric(4,3)
) AS
$$
BEGIN
  RETURN QUERY
  WITH RECURSIVE component AS (
    SELECT
      c.item_uuid,
      coalesce(c.quantity, 1.000) AS quantity,
      i.type
    FROM scm.component c
    INNER JOIN scm.item i
      USING (item_uuid)
    WHERE c.parent_uuid = $1

    UNION ALL

    SELECT
      c.item_uuid,
      (component.quantity * coalesce(c.quantity, 1.000))::numeric(10,3) AS quantity,
      i.type
    FROM component
    INNER JOIN scm.component c
      ON c.parent_uuid = component.item_uuid
    LEFT JOIN scm.item i
      ON i.item_uuid = c.item_uuid
  ), price AS (
    SELECT
      sum(p.gross * component.quantity)::numeric(10,2) AS gross,
      sum(p.cost * component.quantity)::numeric(10,2) AS cost
    FROM component
    INNER JOIN scm.item i
      USING (item_uuid)
    LEFT JOIN prd.price_v p
      USING (product_id)
    WHERE component.type = 'PRODUCT'
  )
  SELECT
    $1 AS item_uuid,
    p.gross,
    p.cost,
    (p.gross - p.cost)::numeric(10,2) AS profit,
    ((p.gross - p.cost) / p.gross)::numeric(4,3) AS margin
  FROM price p;
END
$$
LANGUAGE 'plpgsql';
