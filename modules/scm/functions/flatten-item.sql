CREATE OR REPLACE FUNCTION scm.flatten_item (json, fresh boolean DEFAULT FALSE)
RETURNS TABLE (
  item_uuid uuid,
  parent_uuid uuid,
  code text,
  id text,
  data json,
  boq json,
  attributes json,
  items json,
  depth integer
) AS
$$
BEGIN
  RETURN QUERY
  WITH RECURSIVE item (item_uuid, parent_uuid, code, id, data, boq, attributes, items, depth) AS (
    SELECT
      CASE
        WHEN fresh IS TRUE THEN
          uuid_generate_v4()
        ELSE COALESCE(($1->>'uuid')::uuid, uuid_generate_v4())
      END AS item_uuid,
      NULL::uuid AS parent_uuid, -- Root items must not have a parent_uuid, hence the NULL
      $1->>'code',
      $1->>'id',
      $1->'data',
      $1->'boq',
      $1->'attributes',
      $1->'items',
      0 depth

    UNION ALL

    SELECT
      CASE
        WHEN fresh IS TRUE THEN
          uuid_generate_v4()
        ELSE COALESCE(i.uuid, uuid_generate_v4())
      END AS item_uuid,
      item.item_uuid AS parent_uuid,
      i.code,
      i.id,
      i.data,
      i.boq,
      i.attributes,
      i.items,
      item.depth + 1
    FROM item
    CROSS JOIN json_to_recordset(item.items) AS i(
        uuid uuid,
        parent_uuid uuid,
        code text,
        id text,
        data json,
        boq json,
        attributes json,
        items json
      )
    WHERE json_typeof(item.items) = 'array'
  )
  SELECT *
  FROM item;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION scm.flatten_item (uuid)
RETURNS TABLE (
  item_uuid uuid,
  parent_uuid uuid,
  product_id integer
) AS
$$
BEGIN
  RETURN QUERY
  WITH RECURSIVE item (item_uuid, parent_uuid, product_id) AS (
    SELECT
      item.item_uuid,
      item.parent_uuid,
      item.product_id
    FROM scm.item item
    WHERE item.item_uuid = $1

    UNION ALL

    SELECT
      i.item_uuid,
      i.parent_uuid,
      i.product_id
    FROM item
    INNER JOIN scm.item i
      ON item.item_uuid = i.parent_uuid
  )
  SELECT *
  FROM item;
END
$$
LANGUAGE 'plpgsql';
