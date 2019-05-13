CREATE OR REPLACE FUNCTION scm.create_item (json, OUT result json) AS
$$
DECLARE
  new_item_uuid uuid;
BEGIN
  WITH payload AS (
    SELECT
      p.product_uuid,
      UPPER(p.kind)::scm.item_kind_t AS kind,
      p.name
    FROM json_to_record($1) AS p (
      product_uuid    uuid,
      kind            text,
      name            text
    )
  )
  INSERT INTO scm.item (
    product_uuid,
    kind,
    name
  )
  SELECT
    product_uuid,
    kind,
    name
  FROM payload
  RETURNING item_uuid INTO new_item_uuid;
  
  SELECT json_strip_nulls(to_json(scm.item(new_item_uuid))) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
