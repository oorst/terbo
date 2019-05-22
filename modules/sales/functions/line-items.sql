CREATE OR REPLACE FUNCTION sales.line_items (
  _order_uuid     uuid DEFAULT NULL,
  _line_item_uuid uuid DEFAULT NULL
) 
RETURNS TABLE (
  line_item_uuid     uuid,
  order_uuid         uuid,
  product_uuid       uuid,
  name               text,
  short_desc         text,
  quantity           numeric(10,3),
  uom_name           text,
  uom_abbr           text,
  product_short_desc text,
  price              numeric(10,2),
  margin             numeric(4,3),
  total              numeric(10,2)
) AS
$$
BEGIN  
  RETURN QUERY
  SELECT
    li.*,
    pr.price,
    pr.margin,
    (li.quantity * pr.price)::numeric(10,2)
  FROM sales.line_item_v li
  LEFT JOIN sales.product_price(li.product_uuid) pr
    ON pr.product_uuid = li.product_uuid
  WHERE li.order_uuid = $1
    OR li.line_item_uuid = $2;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sales.line_items (json, OUT result json) AS
$$
BEGIN
  WITH line_items AS (
    SELECT
      *
    FROM sales.line_items(($1->>'order_uuid')::uuid)
  )
  SELECT INTO result
    json_strip_nulls(json_agg(li))
  FROM line_items li;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;