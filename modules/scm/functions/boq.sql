/**

*/

CREATE OR REPLACE FUNCTION scm.boq (uuid)
RETURNS TABLE (
  item_uuid    uuid,
  product_id   integer,
  quantity     numeric(10,3),
  uom_id       integer,
  name         text
) AS
$$
BEGIN
  RETURN QUERY
  WITH product AS (
    SELECT
      i.product_id,
      coalesce(i.quantity, 1.000) AS quantity,
      i.uom_id
    FROM scm.flatten_item($1) i
    WHERE i.product_id IS NOT NULL
  ), sum AS (
    SELECT
      p.product_id,
      p.uom_id,
      sum(p.quantity) AS quantity
    FROM product p
    GROUP BY p.product_id, p.uom_id
  )
  SELECT
    $1 AS item_uuid,
    sum.product_id,
    sum.quantity,
    sum.uom_id,
    pv.name
  FROM sum
  INNER JOIN prd.product_list_v pv
    USING (product_id);
END
$$
LANGUAGE 'plpgsql';
