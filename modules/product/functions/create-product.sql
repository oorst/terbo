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
        *
      FROM payload
      RETURNING *
    )
    SELECT json_strip_nulls(to_json(r)) INTO result
    FROM (
      SELECT
        p.product_id AS "productId",
        p.type,
        p.name,
        f.name
      FROM product p
      LEFT JOIN product f
        ON f.product_id = p.family_id
    ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
