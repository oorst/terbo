CREATE OR REPLACE FUNCTION sales.invoice_details (uuid, OUT result json) AS
$$
BEGIN
  WITH details AS (
    SELECT
      id.amount_payable,
      id.name,
      id.short_desc,
      li.quantity,
      li.uom_name,
      li.uom_abbr,
      li.price,
      li.total
    FROM ar.invoice_detail id
    INNER JOIN sales.line_items(_line_item_uuid => id.detail_uuid) li
      ON li.line_item_uuid = id.detail_uuid
    WHERE id.invoice_uuid = $1
  )
  SELECT INTO result
    json_strip_nulls(json_agg(d))
  FROM details d;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
