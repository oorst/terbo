/*
Generate a bill of materials for the given item
*/
CREATE OR REPLACE FUNCTION scm.get_bom (uuid uuid, OUT result json) AS
$$
BEGIN
WITH RECURSIVE bom AS (
  SELECT
    i.item_uuid AS parent_uuid,
    sub_assm.item_uuid,
    sub_assm.quantity
  FROM scm.item i
  INNER JOIN scm.sub_assembly sub_assm
    ON sub_assm.parent_uuid = i.item_uuid
  WHERE i.item_uuid = $1

  UNION

  SELECT
    i.item_uuid AS parent_uuid,
    sub_assm.item_uuid,
    sub_assm.quantity
  FROM scm.item i
  INNER JOIN scm.sub_assembly sub_assm
    ON sub_assm.parent_uuid = i.item_uuid
  INNER JOIN bom
    ON bom.item_uuid = sub_assm.parent_uuid
)
SELECT json_strip_nulls(json_agg(r)) INTO result
FROM (
  SELECT
    item.name,
    p.name AS "productName",
    composition.explode,
    pricing.gross
  FROM bom
  LEFT JOIN scm.item i
    ON i.item_uuid = bom.item_uuid
  INNER JOIN scm.item_v item
    ON item.uuid = i.item_uuid
  INNER JOIN prd.product p
    ON p.product_id = i.product_id
  INNER JOIN prd.product_abbr_v pav
    ON pav.product_id = p.product_id
  LEFT JOIN prd.composition composition
    USING (composition_id)
  LEFT JOIN prd.component component
    USING (component_id)
  LEFT JOIN prd.product component_product
    ON component_product.product_id = component.cproduct_id
  LEFT JOIN prd.product_abbr_v component_pav
    ON component_pav.product_id = component_product.product_id
  LEFT JOIN prd.product_pricing_v pricing
    ON pricing.product_id = p.product_id OR pricing.product_id = component_product.product_id
  WHERE i.type = 'PART' OR i.type = 'PRODUCT'
) r;
END
$$
LANGUAGE 'plpgsql';
