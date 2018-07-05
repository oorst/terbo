CREATE OR REPLACE FUNCTION prd.create_product (json, OUT result json) AS
$$
BEGIN
  -- Insert tags
  INSERT INTO prd.tag (name)
  SELECT value
  FROM json_array_elements_text($1->'tags')
  ON CONFLICT DO NOTHING;

  WITH
    product AS (
      INSERT INTO prd.product (
        type,
        name,
        description,
        code,
        sku,
        family_id,
        manufacturer_id,
        manufacturer_code,
        supplier_id,
        supplier_code,
        data,
        uom_id
      )
      VALUES (
        $1->>'type',
        NULLIF($1->>'name', ''),
        NULLIF($1->>'description', ''),
        NULLIF($1->>'code', ''),
        NULLIF($1->>'sku', ''),
        ($1->>'familyId')::integer,
        ($1->>'manufacturerId')::integer,
        $1->>'manufacturerCode',
        ($1->>'supplierId')::integer,
        $1->>'supplierCode',
        $1->'data',
        ($1->>'uomId')::integer
      ) RETURNING *
    ),
    -- Link product and tags
    product_tag AS (
      INSERT INTO prd.product_tag (
        product_id,
        tag_id
      )
      SELECT
        (
          SELECT product_id FROM product
        ),
        tag_id
      FROM prd.tag
      WHERE name IN (
        SELECT value
        FROM json_array_elements_text($1->'tags')
      )
      RETURNING *
    ),
    cost AS (
      INSERT INTO prd.cost (
        product_id,
        amount
      )
      SELECT
        (SELECT product_id FROM product),
        c.cost
      FROM json_to_record($1) AS c (cost numeric(10,2)) WHERE NOT (c IS NULL)
    ),
    price AS (
      INSERT INTO prd.price (
        product_id,
        gross,
        net,
        markup,
        markup_id
      )
      SELECT
        (SELECT product_id FROM product),
        p.gross,
        p.net,
        p.markup,
        p.markup_id
      FROM json_to_record($1) AS p (
        gross numeric(10,2),
        net numeric(10,2),
        markup numeric(10,2),
        markup_id integer
      )
      WHERE NOT (p IS NULL)
    )
    SELECT prd.get_product(product_id) INTO result
    FROM product;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
