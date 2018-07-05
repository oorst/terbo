/*
Generate a bill of quantities for the given item
*/
CREATE OR REPLACE FUNCTION scm.get_boq (uuid uuid, OUT result json) AS
$$
BEGIN
WITH RECURSIVE boq AS (
  SELECT
    i.item_uuid AS parent_uuid,
    sub_assm.child_uuid,
    sub_assm.quantity
  FROM scm.item i
  INNER JOIN scm.sub_assembly sub_assm
    ON sub_assm.parent_uuid = i.item_uuid
  WHERE i.item_uuid = $1

  UNION

  SELECT
    i.item_uuid AS parent_uuid,
    sub_assm.child_uuid,
    sub_assm.quantity
  FROM scm.item i
  INNER JOIN scm.sub_assembly sub_assm
    ON sub_assm.parent_uuid = i.item_uuid
  INNER JOIN boq
    ON boq.child_uuid = sub_assm.parent_uuid
)
SELECT json_strip_nulls(json_agg(r)) INTO result
FROM (
  SELECT
    COALESCE(boq.quantity, (i.data->'attributes'->>p.uom_type)::numeric(10,3)) AS quantity,
    p.gross,
    p.uom_type,
    item.name
  FROM boq
  LEFT JOIN scm.item i
    ON i.item_uuid = boq.child_uuid
  INNER JOIN scm.item_v item
    ON item.uuid = i.item_uuid
  INNER JOIN prd.product_v p
    ON p.product_id = i.product_id
  WHERE i.type = 'PART' OR i.type = 'PRODUCT'
) r;
END
$$
LANGUAGE 'plpgsql';
