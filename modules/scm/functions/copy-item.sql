CREATE OR REPLACE FUNCTION scm.copy_item (uuid, OUT copy_uuid uuid) AS
$$
DECLARE

  _copy       RECORD;
  _component  scm.component;

BEGIN
  -- Create the new item
  INSERT INTO scm.item (
    product_id,
    name,
    type,
    data,
    gross,
    net,
    weight
  )
  SELECT
    i.product_id,
    i.name,
    i.type,
    i.data,
    i.gross,
    i.net,
    i.weight
  FROM scm.item i
  WHERE i.item_uuid = $1
  RETURNING * INTO _copy;

  SELECT _copy.item_uuid INTO copy_uuid;

  -- Copy any components and items
  FOR _component IN
    SELECT * FROM scm.component WHERE parent_uuid = $1
  LOOP
    INSERT INTO scm.component (
      parent_uuid,
      item_uuid,
      product_id,
      quantity,
      uom_id
    ) VALUES (
      _copy.item_uuid,
      CASE
        WHEN _component.item_uuid IS NOT NULL THEN
          scm.copy_item(_component.item_uuid) -- Recursion here
        ELSE NULL
      END,
      _component.product_id,
      _component.quantity,
      _component.uom_id
    );
  END LOOP;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION scm.copy_item (json, OUT result json) AS
$$
BEGIN
  WITH component AS (
    SELECT
      c.*
    FROM scm.component c
    WHERE c.component_id = ($1->>'componentId')::integer
  ), new_item AS (
    SELECT
      scm.copy_item(c.item_uuid) AS item_uuid
    FROM component c
  ), new_component AS (
    INSERT INTO scm.component (
      parent_uuid,
      type,
      item_uuid
    )
    SELECT
      c.parent_uuid,
      c.type,
      (SELECT item_uuid FROM new_item)
    FROM component c
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      item_uuid AS "itemUuid"
    FROM new_item
  ) r;
END
$$
LANGUAGE 'plpgsql';
