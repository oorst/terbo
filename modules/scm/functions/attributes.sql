CREATE OR REPLACE FUNCTION scm.attributes (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      a.attribute_id AS "attributeId",
      a.name,
      a.value
    FROM scm.attribute a
    WHERE a.item_uuid = ($1->>'itemUuid')::uuid
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
