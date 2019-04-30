CREATE OR REPLACE FUNCTION prd.create_product (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      p.type::prd.product_t,
      p.name,
      p.short_desc,
      p.family_uuid
    FROM json_to_record($1) AS p (
      type        text,
      name        text,
      short_desc  text,
      family_uuid uuid
    )
  ), product AS (
      INSERT INTO prd.product (
        type,
        name,
        short_desc,
        family_uuid
      )
      SELECT
        p.type,
        p.name,
        p.short_desc,
        p.family_uuid
      FROM payload p
      RETURNING *
    )
    SELECT json_strip_nulls(to_json(r)) INTO result
    FROM (
      SELECT
        p.product_uuid,
        p.type,
        coalesce(p.name, f.name) AS name,
        p.short_desc
      FROM product p
      LEFT JOIN product f
        ON f.product_uuid = p.family_uuid
    ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
