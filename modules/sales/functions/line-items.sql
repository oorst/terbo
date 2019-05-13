CREATE OR REPLACE FUNCTION sales.line_items (
  li_uuid    uuid DEFAULT NULL, -- Line item id
  order_uuid uuid DEFAULT NULL  -- Order id
) RETURNS SETOF sales.line_item_t AS
$$
BEGIN  
  RETURN QUERY
  WITH line_item AS (
    SELECT
      li.*
    FROM sales.line_item li
    WHERE li.order_uuid = $2 OR li.line_item_uuid = $1
  ), _order AS (
    SELECT
      *
    FROM sales.order o
    WHERE o.order_uuid = $2 OR o.order_uuid = (
      SELECT li.order_uuid FROM line_item
    )
  )
  SELECT
    li.line_item_uuid,
    li.order_uuid,
    li.product_uuid,
    li.line_position,
    pv.code,
    pv.sku,
    pv.name,
    pv.short_desc,
    NULL::numeric(5,2),
    NULL::numeric(10,2), -- line_gross
    pr.gross, -- product_gross
    NULL::numeric(10,2), -- line_price
    pr.price, -- product_price
    (pr.gross * li.quantity)::numeric(10,2), --total_gross
    (pr.price * li.quantity)::numeric(10,2), --total_price
    NULL::integer, -- uom_id
    pv.uom_name,
    pv.uom_abbr,
    li.quantity,
    pr.tax_excluded,
    NULL::integer, -- delivery_id
    NULL::public.note[], -- notes
    li.created::timestamptz,
    li.modified::timestamptz
  FROM line_item li
  LEFT JOIN _order o
    ON o.order_uuid = li.order_uuid
  LEFT JOIN prd.product_v pv
    USING (product_uuid)
  LEFT JOIN sales.product_price(
    li.product_uuid,
    CASE
      WHEN sales.line_items.status != 'PENDING' THEN
        sales.line_item.status_changed
      ELSE NULL
    END
  ) pr ON TRUE
  WHERE li.line_item_uuid = li_uuid OR li.order_uuid = $2;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sales.line_items (json, OUT result json) AS
$$
BEGIN
  IF $1->'line_item_uuid' IS NOT NULL THEN
    SELECT 
      json_strip_nulls(to_json(r)) INTO result
    FROM sales.line_items(li_uuid => ($1->>'line_item_uuid')::uuid) r;
  ELSIF $1->'order_id' IS NOT NULL THEN
    SELECT INTO result
      json_strip_nulls(json_agg(r))
    FROM sales.line_items(order_uuid => ($1->>'order_uuid')::uuid) r;
  END IF;
END
$$
LANGUAGE 'plpgsql';