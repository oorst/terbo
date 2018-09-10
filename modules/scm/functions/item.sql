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
      i.name,
      i.description,
      i.attributes,
      i.gross,
      i.created
    FROM scm.item i
    INNER JOIN payload
      USING (item_uuid)
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
