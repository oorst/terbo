CREATE OR REPLACE FUNCTION prd.search (json, OUT result json) AS
$$
-- This function uses regular expressions to match code and names.
-- Probably not very efficient
DECLARE
  regex text;
BEGIN
  -- Throw if no search term is present
  IF $1->>'search' IS NULL THEN
    RAISE EXCEPTION 'no search term provided';
  END IF;

  regex = '.*' || ($1->>'search')::text || '.*';

  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      p.product_id AS id,
      p.uuid,
      p.code,
      p.sku,
      p.manufacturer_code AS "manufacturerCode",
      p.supplier_code AS "supplierCode",
      COALESCE(p.name, fam.name) AS name,
      (
        SELECT f
        FROM (
          SELECT
            fam.name,
            fam.code,
            fam.manufacturer_code AS "manufacturerCode",
            fam.supplier_code AS "supplierCode"
        ) f
        WHERE NOT (f IS NULL)
      ) AS family,
      p.description,
      p.data->'attributes' AS attributes
    FROM prd.product p
    LEFT JOIN prd.product fam
      ON fam.product_id = p.family_id
    WHERE CONCAT(
      p.code,
      p.sku,
      p.name,
      fam.code,
      fam.supplier_code,
      fam.manufacturer_code,
      fam.name
    ) ~* regex
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
