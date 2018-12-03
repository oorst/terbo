CREATE OR REPLACE FUNCTION scm.flatten_item (uuid)
RETURNS TABLE (
  root_uuid   uuid,
  item_uuid   uuid,
  parent_uuid uuid,
  product_id  integer,
  uom_id      integer,
  quantity    numeric(10,3)
) AS
$$
BEGIN
  RETURN QUERY
  WITH RECURSIVE item AS (
    -- Select from components where the parent is the root item or where the
    -- parent is the root item's prototype
    SELECT
      c.item_uuid,
      c.parent_uuid,
      c.product_id,
      c.uom_id,
      coalesce(c.quantity, 1.000)::numeric(10,3) AS quantity
    FROM scm.component c
    WHERE c.parent_uuid IN (
      SELECT
        coalesce(i.prototype_uuid, $1)
      FROM scm.item i
      WHERE i.item_uuid = $1
    );

    UNION ALL

    SELECT
      c.item_uuid,
      i.item_uuid AS parent_uuid,
      c.product_id,
      c.uom_id,
      (i.quantity * coalesce(c.quantity, 1.000))::numeric(10,3) AS quantity
    FROM item i
    INNER JOIN scm.component c
      ON c.parent_uuid = (
        SELECT
          coalesce(ii.prototype_uuid, ii.item_uuid)
        FROM scm.item ii
        WHERE ii.item_uuid = i.item_uuid
      )
  )
  SELECT
    $1 AS root_uuid,
    i.*
  FROM item i;
END
$$
LANGUAGE 'plpgsql';
