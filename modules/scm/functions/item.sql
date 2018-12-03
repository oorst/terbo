CREATE OR REPLACE FUNCTION scm.item(json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."itemUuid" AS item_uuid
    FROM json_to_record($1) AS j (
      "itemUuid" uuid
    )
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      i.item_uuid AS "itemUuid",
      i.prototype_uuid AS "prototypeUuid",
      i.product_id AS "productId",
      pti.name AS "prototypeName",
      i.name,
      i.description,
      i.attributes,
      i.gross,
      i.created,
      pv.name AS "productName",
      pv.code
    FROM payload
    INNER JOIN scm.item i
      USING (item_uuid)
    LEFT JOIN prd.product_list_v pv
      USING (product_id)
    LEFT JOIN scm.item_list_v pti
      ON pti.item_uuid = i.prototype_uuid
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
