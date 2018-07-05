CREATE OR REPLACE FUNCTION product.save_sku (json, OUT result json) AS
$$
BEGIN
  -- A payload without an id is a new SKU
  IF $1->>'id' IS NULL THEN
    WITH sku AS (
      INSERT INTO product.sku (code, data)
      VALUES (
        $1->>'code',
        ($1->'data')::jsonb
      ) RETURNING code, sku_id AS "id", data, modified
    ) SELECT to_json(r) INTO result
    FROM sku r;
  ELSE -- There is an id so just update
    UPDATE product.sku s SET (
      code, data, modified
    ) = (
      $1->>'code',
      ($1->'data')::jsonb,
      CURRENT_TIMESTAMP
    )
    WHERE s.sku_id = ($1->>'id')::integer;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
