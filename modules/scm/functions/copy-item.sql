CREATE OR REPLACE FUNCTION scm.copy_item (uuid, root uuid, OUT copy_uuid uuid) AS
$$
DECLARE

  copy RECORD;
  sub  scm.sub_assembly;

BEGIN
  WITH template AS (
    SELECT
      i.item_uuid,
      i.product_id,
      i.name,
      i.type,
      i.data,
      i.explode,
      i.route_id,
      i.gross,
      i.net,
      i.weight
    FROM scm.item i
    WHERE i.item_uuid = $1
  )
  INSERT INTO scm.item (
    product_id,
    name,
    type,
    data,
    explode,
    route_id,
    gross,
    net,
    weight
  )
  SELECT
    t.product_id,
    t.name,
    t.type,
    t.data,
    t.explode,
    t.route_id,
    t.gross,
    t.net,
    t.weight
  FROM template t
  RETURNING * INTO copy;

  SELECT copy.item_uuid INTO copy_uuid;

  FOR sub IN
    SELECT * FROM scm.sub_assembly WHERE parent_uuid = $1
  LOOP
    INSERT INTO scm.sub_assembly (
      root_uuid,
      parent_uuid,
      item_uuid,
      quantity
    ) VALUES (
      root,
      copy.item_uuid,
      scm.copy_item(sub.item_uuid, root), -- Recursion here
      sub.quantity
    );
  END LOOP;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION scm.copy_item (json, OUT result json) AS
$$
DECLARE

  copy_uuid uuid;

BEGIN
  WITH payload AS (
    SELECT
      j."templateUuid" AS template_uuid,
      j."productId" AS product_id,
      j.name AS name
    FROM json_to_record($1) AS j (
      "templateUuid" uuid,
      "productId"    integer,
      name           text
    )
  ), template AS (
    SELECT
      i.item_uuid,
      coalesce(payload.product_id, i.product_id) AS product_id,
      coalesce(payload.name, i.name) AS name,
      i.type,
      i.data,
      i.explode,
      i.route_id,
      i.gross,
      i.net,
      i.weight
    FROM payload
    INNER JOIN scm.item i
      ON i.item_uuid = payload.template_uuid
  ), copy AS (
    INSERT INTO scm.item (
      product_id,
      name,
      type,
      data,
      explode,
      route_id,
      gross,
      net,
      weight
    )
    SELECT
      t.product_id,
      t.name,
      t.type,
      t.data,
      t.explode,
      t.route_id,
      t.gross,
      t.net,
      t.weight
    FROM template t
    RETURNING *
  ), sub_assembly AS (
    SELECT
      s.*
    FROM template
    LEFT JOIN scm.sub_assembly s
      ON s.parent_uuid = template.item_uuid
  ), sub_assembly_copy AS (
    INSERT INTO scm.sub_assembly (
      root_uuid,
      parent_uuid,
      item_uuid,
      quantity
    )
    SELECT
      copy.item_uuid,
      copy.item_uuid,
      scm.copy_item(s.item_uuid, copy.item_uuid),
      s.quantity
    FROM sub_assembly s
    CROSS JOIN copy
  )
  SELECT
    item_uuid INTO copy_uuid
  FROM copy;

  SELECT scm.get_item(copy_uuid) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
