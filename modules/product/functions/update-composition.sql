CREATE OR REPLACE FUNCTION prd.update_composition (json, OUT result json) AS
$$
DECLARE

  _composition_id prd.composition;

BEGIN
  -- Must provide a parent product id
  IF $1->'parentId' IS NULL THEN
    RAISE EXCEPTION 'must provide a parentId';
  END IF;

  -- If compositionId is null, then create a new composition and update the
  -- parent product
  IF $1->'compositionId' IS NULL THEN
    WITH new_composition AS (
      INSERT INTO prd.composition (
        explode
      )
      SELECT
        explode
      FROM json_to_record($1) AS j (
        "parentId" integer,
        explode    boolean
      )
      RETURNING *
    )
    UPDATE prd.product p SET composition_id = c.composition_id
    FROM new_composition c
    WHERE p.product_id = ($1->>'parentId')::integer;
  -- Update the existing composition
  ELSE
    WITH payload AS (
      SELECT
        j."compositionId" AS composition_id,
        explode
      FROM json_to_record($1) AS j (
        "compositionId" integer,
        explode         boolean
      )
    )
    UPDATE prd.composition c SET (
      explode
    ) = (
      j.explode
    )
    FROM payload j
    WHERE c.composition_id = j.composition_id;
  END IF;

  -- Insert, update or inactivate components as necessary
  WITH payload_component AS (
    SELECT
      j."componentId" AS component_id,
      j."productId" AS product_id,
      j.quantity,
      j.removed
    FROM json_to_recordset($1->'components') AS j (
      "componentId" integer,
      "productId"   integer,
      quantity      numeric(10,3),
      removed       boolean
    )
  ), new_component AS (
    INSERT INTO prd.component (
      parent_id,
      product_id,
      quantity
    )
    SELECT
      ($1->>'parentId')::integer,
      j.product_id,
      j.quantity
    FROM payload_component j
    WHERE j.component_id IS NULL AND j.removed IS NOT TRUE
  ), updated_component AS (
    UPDATE prd.component c SET (
      product_id,
      quantity
    ) = (
      j.product_id,
      j.quantity
    )
    FROM payload_component j
    WHERE c.component_id = j.component_id
  )
  -- Inactivate by setting end_at
  UPDATE prd.component c SET end_at = CURRENT_TIMESTAMP
  FROM payload_component j
  WHERE c.component_id = j.component_id AND j.removed IS TRUE;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
