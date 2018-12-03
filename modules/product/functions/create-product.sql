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
  ), product AS (
      INSERT INTO prd.product (
        type,
        name,
        family_id
      )
      SELECT
        p.type,
        p.name,
        p.family_id
      FROM payload p
      RETURNING *
    ), product_uom AS (
      INSERT INTO prd.product_uom (
        product_id,
        primary_uom
      )
      SELECT
        p.product_id,
        TRUE
      FROM product p
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
