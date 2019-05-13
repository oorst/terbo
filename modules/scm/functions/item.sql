CREATE OR REPLACE FUNCTION scm.item(uuid, OUT result scm.item_t) AS
$$
BEGIN
  SELECT
    i.item_uuid,
    i.product_uuid,
    i.name,
    i.short_desc,
    pv.code,
    pv.name,
    pv.short_desc,
    i.created
  INTO
    result.item_uuid,
    result.product_uuid,
    result.name,
    result.short_desc,
    result.product_code,
    result.product_name,
    result.product_short_desc,
    result.created
  FROM scm.item i
  LEFT JOIN prd.product_list_v pv
    USING (product_uuid)
  WHERE i.item_uuid = $1;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
