CREATE OR REPLACE FUNCTION scm.get_item(uuid, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      i.item_uuid AS uuid,
      i.type,
      i.data,
      i.name,
      p.product_id AS "productId",
      p.name AS "productName",
      p.description AS "productDescription",
      p.sku,
      p.code AS "productCode",
      fam.name AS "productFamilyName",
      fam.code AS "productFamilyCode",
      coalesce(p.name, fam.name) AS "$productName",
      coalesce(i.name, p.name, fam.name) AS "$name",
      coalesce(p.sku, p.code, fam.code) AS "$code",
      parent.item_uuid AS "parentUuid",
      coalesce(parent.name, parentP.name, parentFam.name) AS "$parentName",
      coalesce(parentP.code, parentFam.code) AS "$parentCode",
      (
        SELECT
          array_agg(r)
        FROM (
          SELECT
            ss.sub_assembly_id AS "subAssemblyId",
            ss.quantity,
            ii.item_uuid AS uuid,
            ii.type,
            coalesce(ii.name, pp.name, ff.name) AS "$name"
          FROM scm.sub_assembly ss
          INNER JOIN scm.item ii
            ON ii.item_uuid = ss.item_uuid
          LEFT JOIN prd.product pp
            ON pp.product_id = ii.product_id
          LEFT JOIN prd.product ff
            ON ff.product_id = pp.family_id
          WHERE ss.parent_uuid = i.item_uuid
        ) r
      ) AS "subAssemblies",
      i.gross,
      (SELECT sum(line_total) from scm.item_boq(i.item_uuid)) AS "$gross"
    FROM scm.item i
    LEFT JOIN prd.product p
      USING (product_id)
    LEFT JOIN prd.product fam
      ON fam.product_id = p.family_id
    LEFT JOIN scm.sub_assembly s
      ON s.item_uuid = i.item_uuid
    LEFT JOIN scm.item parent
      ON parent.item_uuid = s.parent_uuid
    LEFT JOIN prd.product parentp
      ON parentp.product_id = parent.product_id
    LEFT JOIN prd.product parentFam
      ON parentFam.product_id = parentP.family_id
    WHERE i.item_uuid = $1
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION scm.get_item(json, OUT result json) AS
$$
BEGIN
  IF $1->>'uuid' IS NULL THEN
    RAISE EXCEPTION 'no item uuid provided';
  END IF;

  SELECT scm.get_item(($1->>'uuid')::uuid) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
