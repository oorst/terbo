/**
@function
  This function only updates fields that have an existant corresponding key/value
  in the JSON payload.

  If you want to set a field to NULL then set the corresponding field to `null`
  in the JSON payload.

  When cost or pricing is included a new cost and/or price record is created to
  maintain a history.

  @def prd.update_product (json)
  @returns {json}
  @api
*/
CREATE OR REPLACE FUNCTION prd.update_product (json, OUT result json) AS
$$
BEGIN
  WITH existing AS (
    SELECT *
    FROM prd.product
    WHERE product_id = ($1->>'id')::integer
  )
  UPDATE prd.product u
  SET (
    code,
    name,
    description,
    type,
    data,
    family_id,
    manufacturer_id,
    manufacturer_code,
    supplier_id,
    supplier_code,
    uom_id,
    modified
  ) = (
    CASE
      WHEN $1->'code' IS NULL THEN -- Note use of single bracket selector
        x.code
      ELSE NULLIF($1->>'code', '')
    END,
    -- name
    CASE
      WHEN $1->'name' IS NULL THEN
        x.name
      ELSE NULLIF($1->>'name', '')
    END,
    -- description
    CASE
      WHEN $1->'description' IS NULL THEN
        x.description
      ELSE NULLIF($1->>'description', '')
    END,
    -- type
    CASE
      WHEN $1->'type' IS NULL THEN
        x.type
      ELSE $1->>'type'
    END,
    -- Data
    CASE
      WHEN $1->'data' IS NULL THEN
        x.data
      ELSE ($1->'data')::jsonb
    END,
    CASE
      WHEN $1->'familyId' IS NULL THEN
        x.family_id
      ELSE ($1->>'familyId')::integer
    END,
    CASE
      WHEN $1->'manufacturerId' IS NULL THEN
        x.manufacturer_id
      ELSE ($1->>'manufacturerId')::integer
    END,
    CASE
      WHEN $1->'manufacturerCode' IS NULL THEN
        x.manufacturer_code
      ELSE NULLIF($1->>'manufacturerCode', '')
    END,
    CASE
      WHEN $1->'supplierId' IS NULL THEN
        x.supplier_id
      ELSE ($1->>'supplierId')::integer
    END,
    CASE
      WHEN $1->'supplierCode' IS NULL THEN
        x.supplier_code
      ELSE NULLIF($1->>'supplierCode', '')
    END,
    CASE
      WHEN $1->'uomId' IS NULL THEN
        x.uom_id
      ELSE ($1->>'uomId')::integer
    END,
    -- modified
    CURRENT_TIMESTAMP
  )
  FROM existing x
  WHERE u.product_id = x.product_id;

  -- Price
  WITH existing_price AS (
    SELECT DISTINCT ON (price.product_id)
      product_id,
      gross,
      net,
      markup,
      markup_id
    FROM prd.price price
    WHERE price.product_id = 19
    ORDER BY price.product_id, price.price_id DESC
  )
  INSERT INTO prd.price (
    product_id,
    gross,
    net,
    markup,
    markup_id
  )
  SELECT
    ($1->>'id')::integer,
    CASE
      WHEN $1->'gross' IS NULL THEN
        existing_price.gross
      ELSE price.gross
    END,
    CASE
      WHEN $1->'net' IS NULL THEN
        existing_price.net
      ELSE price.net
    END,
    CASE
      WHEN $1->'markup' IS NULL THEN
        existing_price.markup
      ELSE price.markup
    END,
    CASE
      WHEN $1->'markupId' IS NULL THEN
        existing_price.markup_id
      ELSE price."markupId"
    END
  FROM json_to_record($1) AS
    price(gross numeric(10,2), net numeric(10,2), markup numeric(10,2), "markupId" integer, "productId" integer)
  LEFT JOIN existing_price
    ON existing_price.product_id = price."productId"
  WHERE price.gross IS DISTINCT FROM existing_price.gross
    OR price.net IS DISTINCT FROM existing_price.net
    OR price.markup IS DISTINCT FROM existing_price.markup
    OR price."markupId" IS DISTINCT FROM existing_price.markup_id;

  -- Insert a new cost if one is present in the params and is different to the
  -- current cost
  IF $1->>'cost' IS NOT NULL
  AND ($1->>'cost')::numeric(10,2) IS DISTINCT FROM prd.current_cost(($1->>'id')::integer) THEN
    INSERT INTO prd.cost (
      product_id,
      amount
    ) VALUES (
      ($1->>'id')::integer,
      ($1->>'cost')::numeric(10,2)
    );
  END IF;

  -- End the current cost if $1->>'cost' is set to null
  IF json_typeof($1->'cost') = 'null' THEN
    WITH current_cost AS (
      SELECT DISTINCT ON (cost.product_id)
        cost.cost_id
      FROM prd.cost cost
      WHERE cost.product_id = ($1->>'id')::integer
      ORDER BY cost.product_id, cost.cost_id DESC
    )
    UPDATE prd.cost cost SET end_at = CURRENT_TIMESTAMP
    FROM current_cost
    WHERE cost.cost_id = current_cost.cost_id;
  END IF;

  SELECT prd.get_product(($1->>'id')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
