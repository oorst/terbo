CREATE OR REPLACE FUNCTION scm.flatten_item (uuid)
RETURNS TABLE (
  item_uuid uuid,
  product_id  integer,
  type        scm_item_t,
  name        text,
  data        jsonb,
  explode     integer,
  route_id    integer,
  gross       numeric(10,2),
  net         numeric(10,2),
  weight      numeric(10,2),
  created     timestamp,
  end_at      timestamp,
  modified    timestamp,
  quantity    numeric(10,3),
  parent_uuid uuid
) AS
$$
BEGIN
  RETURN QUERY
  WITH RECURSIVE item AS (
    SELECT
      i.item_uuid,
      i.product_id,
      i.type,
      i.name,
      i.data,
      i.explode,
      i.route_id,
      i.gross,
      i.net,
      i.weight,
      i.created,
      i.end_at,
      i.modified,
      1::numeric(10,3) AS quantity,
      NULL::uuid AS parent_uuid
    FROM scm.item i
    WHERE i.item_uuid = $1

    UNION ALL

    SELECT
      child.item_uuid,
      i.product_id,
      i.type,
      i.name,
      i.data,
      i.explode,
      i.route_id,
      i.gross,
      i.net,
      i.weight,
      i.created,
      i.end_at,
      i.modified,
      (item.quantity * coalesce(child.quantity, 1.000))::numeric(10,3) AS quantity,
      item.item_uuid AS parent_uuid
    FROM scm.sub_assembly child
    INNER JOIN item
      ON item.item_uuid = child.parent_uuid
    LEFT JOIN scm.item i
      ON i.item_uuid = child.item_uuid
  )
  SELECT
    *
  FROM item;
END
$$
LANGUAGE 'plpgsql';
