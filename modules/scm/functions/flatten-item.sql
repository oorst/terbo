CREATE OR REPLACE FUNCTION scm.flatten_item (uuid)
RETURNS TABLE (
  root_uuid   uuid,
  item_uuid   uuid,
  parent_uuid uuid,
  level       integer,
  product_id  integer,
  uom_id      integer,
  quantity    numeric(10,3)
) AS
$$
BEGIN
  RETURN QUERY
  WITH RECURSIVE item AS (
    SELECT
      i.item_uuid,
      NULL::uuid AS parent_uuid,
      1 AS level,
      i.product_id,
      NULL::integer AS uom_id,
      NULL::numeric(10,3) AS quantity
    FROM scm.item i
    WHERE i.item_uuid = $1

    UNION ALL

    SELECT
      c.item_uuid,
      i.item_uuid AS parent_uuid,
      i.level + 1 AS level,
      c.product_id,
      c.uom_id,
      c.quantity
    FROM item i
    INNER JOIN scm.component c
      ON c.parent_uuid = i.item_uuid
  )
  SELECT
    $1 AS root_uuid,
    i.*
  FROM item i;
END
$$
LANGUAGE 'plpgsql';
