CREATE OR REPLACE FUNCTION scm.item_bom (uuid)
RETURNS TABLE (
  product_id   integer,
  item_uuid    uuid,
  item_name    text,
  product_name text,
  cost         numeric(10,2),
  markup       numeric(10,2),
  gross        numeric(10,2),
  quantity     numeric(10,3),
  line_total   numeric(10,2)
) AS
$$
BEGIN
  RETURN QUERY
  WITH RECURSIVE item AS (
    SELECT
      i.item_uuid,
      i.type,
      i.data,
      i.product_id,
      i_v.name AS item_name,
      p.composition_id,
      child.item_uuid AS child_uuid,
      COALESCE(
        (i.data->'attributes'->>'quantity')::numeric(10,3),
        (i.data->'attributes'->>uom.type)::numeric(10,3),
        1.000
      )::numeric(10,3) AS quantity,
      uom.type AS uom_type
    FROM scm.item i
    INNER JOIN scm.item_v i_v
      USING (item_uuid)
    INNER JOIN prd.product p
      ON p.product_id = i.product_id
    LEFT JOIN prd.uom uom
      USING (uom_id)
    LEFT JOIN scm.sub_assembly child
      ON child.parent_uuid = i.item_uuid
    WHERE i.item_uuid = $1

    UNION ALL

    SELECT
      i.item_uuid,
      i.type,
      i.data,
      i.product_id,
      i_v.name AS item_name,
      p.composition_id,
      child.item_uuid AS child_uuid,
      COALESCE(
        item_sub.quantity,
        (i.data->'attributes'->>'quantity')::numeric(10,3),
        (i.data->'attributes'->>uom.type)::numeric(10,3),
        0
      )::numeric(10,3) AS quantity,
      uom.type AS uom_type
    FROM scm.item i
    INNER JOIN scm.item_v i_v
      USING (item_uuid)
    INNER JOIN prd.product p
      ON p.product_id = i.product_id
    INNER JOIN item
      ON item.child_uuid = i.item_uuid
    LEFT JOIN prd.uom uom
      USING (uom_id)
    INNER JOIN scm.sub_assembly item_sub
      ON item_sub.item_uuid = item.child_uuid
    LEFT JOIN scm.sub_assembly child
      ON child.parent_uuid = i.item_uuid
  ),
  product AS (
    SELECT DISTINCT ON (item.item_uuid) -- Ensure no duplicates here
      item.item_uuid,
      item.product_id,
      item.item_name,
      CASE
        WHEN composition.explode IS TRUE THEN
          composition.composition_id
        ELSE NULL
      END AS composition_id,
      item.quantity,
      pv.name AS product_name
    FROM item
    LEFT JOIN prd.composition composition
      ON composition.composition_id = item.composition_id
    LEFT JOIN prd.product_abbr_v pv
      ON pv.product_id = item.product_id
    WHERE item.type IN ('PART', 'PRODUCT')

    UNION ALL

    SELECT
      product.item_uuid,
      p.product_id,
      product.item_name,
      CASE
        WHEN composition.explode IS TRUE THEN
          composition.composition_id
        ELSE NULL
      END AS composition_id,
      (product.quantity * component.quantity)::numeric(10,3) AS quantity,
      pv.name AS product_name
    FROM prd.component component
    INNER JOIN product
      ON product.composition_id = component.composition_id
    INNER JOIN prd.product p
      ON p.product_id = component.product_id
    LEFT JOIN prd.composition composition
      ON composition.composition_id = p.composition_id
        AND composition.explode IS TRUE
    LEFT JOIN prd.component child
      ON child.composition_id = composition.composition_id
    LEFT JOIN prd.product_abbr_v pv
      ON pv.product_id = component.product_id
  )
  SELECT
    product.product_id,
    product.item_uuid,
    product.item_name,
    product.product_name,
    pr.cost,
    pr.markup,
    pr.gross,
    product.quantity,
    (product.quantity * pr.gross)::numeric(10,2) AS line_total
  FROM product
  INNER JOIN prd.product_pricing_v pr
    USING (product_id)
  WHERE product.composition_id IS NULL;
END
$$
LANGUAGE 'plpgsql';
