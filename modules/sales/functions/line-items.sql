CREATE OR REPLACE FUNCTION sales.line_items (uuid) 
RETURNS SETOF sales.line_item_t AS
$$
BEGIN  
  RETURN QUERY
  SELECT
    li.*
  FROM sales.line_item l
  LEFT JOIN sales.line_item(l.line_item_uuid) li
    ON li.line_item_uuid = l.line_item_uuid
  WHERE l.order_uuid = $1;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sales.line_items (json, OUT result json) AS
$$
BEGIN
  SELECT INTO result
    json_strip_nulls(json_agg(r))
  FROM sales.line_items(($1->>'order_uuid')::uuid) r;
END
$$
LANGUAGE 'plpgsql';