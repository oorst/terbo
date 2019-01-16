/**
Return the omponents of an item.

The boq does not contain the root item the boq was generated from
*/

DROP FUNCTION scm.boq(uuid);
CREATE OR REPLACE FUNCTION scm.boq (uuid)
RETURNS TABLE (
  item_uuid    uuid,
  product_id   integer,
  quantity     numeric(10,3),
  uom_id       integer
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
    WHERE i.item_uuid IS DISTINCT FROM $1
      AND i.product_id IS NOT NULL
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
    sum.uom_id
  FROM sum;
END
$$
LANGUAGE 'plpgsql';
