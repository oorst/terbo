CREATE OR REPLACE FUNCTION sales.delete_line_item (json, OUT result json) AS
$$
BEGIN
  DELETE FROM sales.line_item li
  WHERE li.line_item_id = ($1->>'lineItemId')::integer;

  SELECT format('{ "lineItemId": %s, "ok": true }', ($1->>'lineItemId')::integer)::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
