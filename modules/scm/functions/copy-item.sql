CREATE OR REPLACE FUNCTION scm.copy_item (uuid, root uuid, OUT copy_uuid uuid) AS
$$
DECLARE

  copy      RECORD;
  component scm.component;

BEGIN
  INSERT INTO scm.item (
    product_id,
    name,
    type,
    data,
    attributes,
    route_id,
    gross,
    net,
    weight
  )
  SELECT
    i.product_id,
    i.name,
    i.type,
    i.data,
    i.attributes,
    i.route_id,
    i.gross,
    i.net,
    i.weight
  FROM scm.item i
  WHERE i.item_uuid = $1
  RETURNING * INTO copy;

  SELECT copy.item_uuid INTO copy_uuid;

  FOR component IN
    SELECT * FROM scm.component WHERE parent_uuid = $1
  LOOP
    INSERT INTO scm.component (
      root_uuid,
      parent_uuid,
      item_uuid,
      quantity
    ) VALUES (
      coalesce(root, copy.item_uuid),
      copy.item_uuid,
      scm.copy_item(sub.item_uuid, coalesce(root, copy.item_uuid)), -- Recursion here
      sub.quantity
    );
  END LOOP;
END
$$
LANGUAGE 'plpgsql';
