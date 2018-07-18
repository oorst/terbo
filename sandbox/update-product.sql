SELECT
  pv._name,
  i.quantity AS i_q,
  i.item_uuid,
  i.product_id,
  COALESCE(
    (i.data->'attributes'->>'quantity')::numeric(10,3) * i.quantity,
    (i.data->'attributes'->>uom.type)::numeric(10,3) * i.quantity,
    i.quantity
  )::numeric(10,3) AS quantity,
  i.explode
FROM scm.flatten_item('977cddd2-c3cd-443a-81af-4af478a414e5'::uuid) i
INNER JOIN prd.product p
  USING (product_id)
INNER JOIN prd.product_list_v pv
  ON pv.product_id = p.product_id
LEFT JOIN prd.uom uom -- Left join as some products may have null uom_id
  ON uom.uom_id = p.uom_id
WHERE i.type = 'PART' OR i.type = 'PRODUCT';
