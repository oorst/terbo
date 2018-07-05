CREATE OR REPLACE FUNCTION scm.update_item (json, OUT result json) AS
$$
BEGIN
  IF $1->'uuid' IS NULL THEN
    RAISE EXCEPTION 'uuid not provided';
  END IF;

  WITH payload AS (
    -- If a property on the payload is JSON null provide a dummy value to
    -- indicate that the corresponding column should set to null
    SELECT
      p.uuid AS item_uuid,

      CASE WHEN json_typeof($1->'productId') = 'null' IS NULL THEN -1
      ELSE p."productId" END AS product_id,

      CASE WHEN json_typeof($1->'name') = 'null' IS NULL THEN ''
      ELSE p.name END AS name,

      CASE WHEN json_typeof($1->'data') = 'null' IS NULL THEN 'null'::jsonb
      ELSE p.data::jsonb END AS data,

      CASE WHEN json_typeof($1->'routeId') = 'null' IS NULL THEN -1
      ELSE p."routeId" END AS route_id

    FROM json_to_record($1) AS p (
      uuid        uuid,
      "productId" integer,
      name        text,
      data        jsonb,
      "routeId"   integer
    )
  )
  UPDATE scm.item i
  SET (
    product_id,
    name,
    data,
    route_id,
    modified
  ) = (
    CASE p.product_id
      WHEN -1 THEN NULL
      WHEN NULL THEN i.product_id
      ELSE p.product_id
    END,
    CASE p.name
      WHEN '' THEN NULL
      WHEN NULL THEN i.product_id
      ELSE p.product_id
    END,
    CASE p.data
      WHEN 'null'::json THEN NULL
      WHEN NULL THEN i.data
      ELSE p.data
    END,
    CASE p.route_id
      WHEN -1 THEN NULL
      WHEN NULL THEN i.route_id
      ELSE p.route_id
    END,
    -- modified
    CURRENT_TIMESTAMP
  )
  FROM payload p
  WHERE i.item_uuid = p.item_uuid;

  -- Insert new sub-assemblies.  New sub assemblies don't have a subAssemblyId
  WITH sub_assembly AS (
    SELECT
      s."uuid" AS uuid
    FROM json_to_recordset($1->'subAssemblies') AS
      s (
        "subAssemblyId" integer,
        "uuid" uuid
      )
    WHERE s."subAssemblyId" IS NULL
  )
  INSERT INTO scm.sub_assembly (
    parent_uuid,
    item_uuid
  )
  SELECT
    ($1->>'uuid')::uuid,
    uuid
  FROM sub_assembly;

  -- Update sub-assemblies
  UPDATE scm.sub_assembly sub
  SET (
    quantity
  ) = (
    payload.quantity
  )
  FROM json_to_recordset($1->'subAssemblies') AS payload ("subAssemblyId" integer, quantity numeric(10,3), removed boolean)
  WHERE payload."subAssemblyId" = sub.sub_assembly_id AND payload.removed IS NOT TRUE AND (
    payload.quantity IS DISTINCT FROM sub.quantity
  );

  -- Delete removed sub-assemblies
  WITH sub_assembly AS (
    SELECT
      s."subAssemblyId",
      s."uuid"
    FROM json_to_recordset($1->'subAssemblies') AS
      s (
        "subAssemblyId" integer,
        "uuid" uuid,
        removed boolean
      )
    WHERE s.removed IS TRUE
  )
  DELETE FROM scm.sub_assembly s
  USING sub_assembly _s
  WHERE s.sub_assembly_id = _s."subAssemblyId";

  SELECT scm.get_item(($1->>'uuid')::uuid) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
