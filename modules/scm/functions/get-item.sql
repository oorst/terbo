CREATE OR REPLACE FUNCTION scm.get_item(uuid, OUT result json) AS
$$
BEGIN
  WITH RECURSIVE component AS (
    SELECT
      c.item_uuid,
      c.quantity,
      i.type
    FROM scm.component c
    INNER JOIN scm.item i
      USING (item_uuid)
    WHERE c.parent_uuid = $1

    UNION ALL

    SELECT
      c.item_uuid,
      (component.quantity * c.quantity)::numeric(10,3) AS quantity,
      i.type
    FROM component
    INNER JOIN scm.component c
      ON c.parent_uuid = component.item_uuid
    LEFT JOIN scm.item i
      ON i.item_uuid = c.item_uuid
  ), price AS (
    SELECT
      sum(p.gross * component.quantity)::numeric(10,2) AS gross,
      sum(p.cost * component.quantity)::numeric(10,2) AS cost
    FROM component
    INNER JOIN scm.item i
      USING (item_uuid)
    LEFT JOIN prd.price_v p
      USING (product_id)
    WHERE component.type = 'PRODUCT'
  ), computed_price AS (
    SELECT
      p.gross,
      p.cost,
      (p.gross - p.cost)::numeric(10,2) AS profit,
      ((p.gross - p.cost) / p.gross)::numeric(4,3) AS margin
    FROM price p
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      i.item_uuid AS "itemUuid",
      i.type,
      i.data,
      i.name,
      i.short_desc AS "shortDescription",
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
      (SELECT gross FROM computed_price) AS gross,
      (SELECT cost FROM computed_price) AS cost,
      (SELECT profit FROM computed_price) AS profit,
      (SELECT margin FROM computed_price) AS margin
    FROM scm.item i
    LEFT JOIN prd.product p
      USING (product_id)
    LEFT JOIN prd.product fam
      ON fam.product_id = p.family_id
    LEFT JOIN scm.component c
      ON c.item_uuid = i.item_uuid
    LEFT JOIN scm.item parent
      ON parent.item_uuid = c.parent_uuid
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
  SELECT scm.get_item(($1->>'itemUuid')::uuid) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
