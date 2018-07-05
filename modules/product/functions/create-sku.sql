CREATE OR REPLACE FUNCTION product.create_sku (json, OUT result json) AS
$$
BEGIN
  INSERT INTO product.sku (name, code, data)
  VALUES (
    $1->>'name',
    $1->>'code',
    ($1->'data')::jsonb
  )

  result = '{"ok": true}'::json
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
