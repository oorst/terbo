CREATE OR REPLACE FUNCTION scm.item_boq (uuid)
RETURNS TABLE (
  item_uuid  uuid,
  product_id integer,
  name       text,
  type       prd.product_t,
  uom_id     integer,
  quantity   numeric(10,3)
) AS
$$
BEGIN
  RETURN QUERY
  WITH item AS (
    SELECT
      i.item_uuid,
      i.product_id,
      i.quantity
    FROM scm.flatten_item($1) i
    WHERE i.type = 'PRODUCT'
  )
  SELECT
    $1 AS item_uuid,
    i.product_id,
    pv.name,
    p.type,
    p.uom_id,
    i.quantity
  FROM item i
  INNER JOIN prd.product_list_v pv
    USING (product_id)
  INNER JOIN prd.product p
    ON p.product_id = i.product_id;
END
$$
LANGUAGE 'plpgsql';
