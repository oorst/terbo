CREATE OR REPLACE FUNCTION scm.search_items (json, OUT result json) AS
$$
BEGIN
  -- Throw if no search term is present
  IF $1->>'search' IS NULL THEN
    RAISE EXCEPTION 'no search term provided';
  END IF;

  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      i.item_uuid AS uuid,
      i.product_id AS "productId",
      i.name,
      p.code AS "productCode",
      fam.code AS "productFamilyCode",
      coalesce(p.code, fam.code) AS "$code",
      p.name AS "productName",
      fam.name AS "productFamilyName",
      coalesce(i.name, p.name, fam.name) AS "$name",
      root_i.item_uuid AS "rootUuid",
      parent_i.item_uuid AS "parentUuid",
      root_i.name AS "rootName",
      parent_i.name AS "parentName"
    FROM scm.item i
    INNER JOIN prd.product p
      USING (product_id)
    LEFT JOIN prd.product fam
      ON fam.product_id = p.family_id
    LEFT JOIN scm.sub_assembly sub
      ON sub.item_uuid = i.item_uuid
    LEFT JOIN scm.item_v root_i
      ON root_i.item_uuid = sub.root_uuid
    LEFT JOIN scm.item_v parent_i
      ON parent_i.item_uuid = sub.parent_uuid
      WHERE to_tsvector(
        concat_ws(' ',
          i.name,
          p.name,
          p.code,
          fam.name,
          fam.code
        )
      ) @@ plainto_tsquery($1->>'search')
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
