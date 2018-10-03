CREATE OR REPLACE FUNCTION prd.create_product (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j.type::product_t,
      j.name,
      j."familyId" AS family_id
    FROM json_to_record($1) AS j (
      type     text,
      name     text,
      "familyId" integer
    )
  ), product_uom AS (
    INSERT INTO prd.product_uom (
      created_by
    ) VALUES (
      (
        SELECT
          party_id
        FROM person
        WHERE email = SESSION_USER
      )
    )

    RETURNING product_uom_id
  ), product AS (
      INSERT INTO prd.product (
        type,
        name,
        family_id,
        product_uom_id
      )
      SELECT
        p.type,
        p.name,
        p.family_id,
        (SELECT product_uom_id FROM product_uom)
      FROM payload p
      RETURNING *
    )
    SELECT json_strip_nulls(to_json(r)) INTO result
    FROM (
      SELECT
        p.product_id AS "productId",
        p.type,
        coalesce(p.name, f.name) AS name
      FROM product p
      LEFT JOIN product f
        ON f.product_id = p.family_id
    ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
