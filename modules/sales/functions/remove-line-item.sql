CREATE OR REPLACE FUNCTION sales.remove_line_item (json, OUT result json) AS
$$
BEGIN
  UPDATE sales.line_item
  SET end_at = CURRENT_TIMESTAMP
  WHERE line_item_id = ($1->>'lineItemId')::integer;

  SELECT format('{ "ok": true, "removed": true, "lineItemId": %s }', ($1->>'lineItemId')) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
