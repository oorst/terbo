CREATE OR REPLACE FUNCTION pcm.line_items (
  _line_item_id      integer DEFAUlT NULL,
  _purchase_order_id integer DEFAULT NULL
) RETURNS TABLE (
  line_item_id      integer,
  purchase_order_id integer,
  product_id        integer,
  quantity          numeric(10,3),
  uom_name          text,
  uom_abbr          text,
  product_name      text,
  product_code      text,
  short_desc        text
) AS
$$
BEGIN
  RETURN QUERY
  SELECT
    li.line_item_id,
    li.purchase_order_id,
    li.product_id,
    li.quantity,
    pv.uom_name,
    pv.uom_abbr,
    pv.name AS product_name,
    pv.code AS product_code,
    pv.short_desc AS product_short_desc
  FROM pcm.line_item li
  LEFT JOIN prd.product_v pv
    USING (product_id)
  WHERE li.line_item_id = _line_item_id OR li.purchase_order_id = _purchase_order_id;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION pcm.line_items (json, OUT result json) AS
$$
BEGIN
  IF $1->'line_item_id' IS NOT NULL THEN
    SELECT 
      json_strip_nulls(to_json(r)) INTO result
    FROM pcm.line_items(_line_item_id => ($1->>'line_item_id')::integer) r;
  ELSIF $1->'purchase_order_id' IS NOT NULL THEN
    SELECT INTO result
      json_strip_nulls(json_agg(r))
    FROM pcm.line_items(_purchase_order_id => ($1->>'purchase_order_id')::integer) r;
  END IF;
END
$$
LANGUAGE 'plpgsql';
