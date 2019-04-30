CREATE OR REPLACE FUNCTION pcm.purchase_order (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      po.purchase_order_id,
      po.purchase_order_num AS purchase_order_number,
      po.order_id,
      po.supplier_id,
      po.status,
      po.data->'line_items' AS line_items,
      po.created_by,
      po.created,
      po.modified,
      pv.name AS supplier_name
    FROM pcm.purchase_order po
    LEFT JOIN party_v pv
      ON pv.party_id = po.supplier_id
    WHERE po.purchase_order_id = ($1->>'purchase_order_id')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql';
