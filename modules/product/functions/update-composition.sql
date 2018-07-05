CREATE OR REPLACE FUNCTION prd.update_composition (json, OUT result json) AS
$$
BEGIN
  -- Update and return the composition
  WITH composition AS (
    UPDATE prd.composition c SET (
      explode
    ) = (
      -- Ensure explode is always a boolean
      CASE
        WHEN payload_composition.explode IS NULL THEN
          FALSE
        ELSE payload_composition.explode
      END
    )
    FROM json_to_record($1) AS payload_composition (
      id      integer,
      explode boolean
    )
    WHERE c.composition_id = payload_composition.id
    RETURNING c.*
  ), payload_component AS (
    SELECT
      composition.composition_id,
      component.id AS component_id,
      component."productId" AS product_id,
      component.quantity,
      component.removed
    FROM json_to_recordset($1->'components') AS component (
      id            integer,
      "productId"   integer,
      quantity      numeric(10,3),
      removed       boolean
    )
    CROSS JOIN composition
  ), updated_component AS (
    UPDATE prd.component ex SET (
      product_id,
      quantity
    ) = (
      payload.product_id,
      payload.quantity
    )
    FROM payload_component payload
    WHERE ex.component_id = payload.component_id
    RETURNING ex.*
  ), new_component AS (
    INSERT INTO prd.component (
      composition_id,
      product_id,
      quantity
    )
    SELECT
      composition_id,
      product_id,
      quantity
    FROM payload_component payload
    WHERE payload.component_id IS NULL AND payload.removed IS NOT TRUE
    RETURNING *
  ), deleted AS (
    DELETE FROM prd.component existing
    USING payload_component
    WHERE existing.component_id = payload_component.component_id
      AND payload_component.removed IS TRUE
    RETURNING existing.*
  )
  SELECT '{"ok": true }'::json INTO result;

  IF $1->>'id' IS NOT NULL THEN
    -- Delete empty compositions
    DELETE FROM prd.composition c
    WHERE NOT EXISTS (
      SELECT
      FROM prd.component component
      WHERE  component.composition_id = ($1->>'id')::integer
   );

    RETURN;
  END IF;

  -- Create a new composition and components if required
  WITH composition AS (
    INSERT INTO prd.composition (
      explode
    )
    SELECT
      composition.explode
    FROM json_to_record($1) AS composition (explode boolean)
    RETURNING *
  ), payload_component AS (
    SELECT
      composition.composition_id,
      component."productId" AS product_id,
      component.quantity,
      component.removed
    FROM json_to_recordset($1->'components') AS component (
      "productId" integer,
      quantity    numeric(10,3),
      removed     boolean
    )
    CROSS JOIN composition
  ), new_component AS (
    INSERT INTO prd.component (
      composition_id,
      product_id,
      quantity
    )
    SELECT
      composition_id,
      product_id,
      quantity
    FROM payload_component
    WHERE removed IS NOT TRUE
    RETURNING *
  ),
  product AS (
    UPDATE prd.product p SET (composition_id) = (composition.composition_id)
    FROM composition
    WHERE p.product_id = ($1->>'productId')::integer
  )
  SELECT '{ "ok": true }'::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
