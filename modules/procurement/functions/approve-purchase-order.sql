/*
Create the necessary purchase orders for a sales.order.
*/

CREATE OR REPLACE FUNCTION pcm.approve_purchase_order (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      p.purchase_order_id
    FROM json_to_record($1) AS p (
      purchase_order_id integer
    )
  ), current_line_item AS (
    SELECT
      json_agg(d) AS data
    FROM payload p
    INNER JOIN pcm.line_item li
      USING (purchase_order_id)
    LEFT JOIN LATERAL (
      SELECT
        li.*,
        pv.name AS product_name,
        pv.code AS product_code,
        pv.short_desc AS product_short_desc,
        pv.uom_name,
        pv.uom_abbr
      FROM prd.product_v pv
      WHERE pv.product_id = li.product_id
    ) d ON d.line_item_id = li.line_item_id
  ), purchase_order AS (
    UPDATE pcm.purchase_order po SET (
      status,
      data
    ) = (
      'ISSUED'::purchase_order_status_t,
      (
        json_build_object(
          'line_items', (SELECT data FROM current_line_item)
        )
      )
    )
    FROM payload p
    WHERE po.purchase_order_id = p.purchase_order_id
    RETURNING po.*
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      po.purchase_order_id,
      po.status
    FROM purchase_order po
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
