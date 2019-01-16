/**
Return the BOM of an item
*/

DROP FUNCTION scm.bom(uuid);
CREATE OR REPLACE FUNCTION scm.bom (uuid)
RETURNS TABLE (
  item_uuid    uuid,
  product_id   integer,
  uom_id       integer,
  quantity     numeric(10,3)
) AS
$$
BEGIN
  RETURN QUERY
  SELECT
    $1 AS item_uuid,
    p.product_id,
    p.uom_id,
    sum((i.quantity * p.quantity)::numeric(10,3)) AS quantity
  FROM scm.flatten_item($1) i
  LEFT JOIN prd.flatten_product(i.product_id, i.uom_id) p
    ON p.root_id = i.product_id
      AND p.is_leaf IS TRUE
  INNER JOIN prd.product q
    ON q.product_id = p.product_id
      AND q.type = 'PRODUCT'
  WHERE i.item_uuid IS DISTINCT FROM $1
    AND i.item_uuid IS NULL -- Component must not be an item
    AND i.product_id IS NOT NULL -- Component must have a product_id
  GROUP BY p.product_id, p.uom_id;
END
$$
LANGUAGE 'plpgsql';
