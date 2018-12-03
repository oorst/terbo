CREATE OR REPLACE FUNCTION scm.create_attribute (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      p."itemUuid" AS item_uuid,
      p.name,
      p.value
    FROM json_to_record($1) AS p (
      "itemUuid" uuid,
      name       text,
      value      text
    )
  ), new_attribute AS (
    INSERT INTO scm.attribute (
      item_uuid,
      name,
      value
    )
    SELECT
      *
    FROM payload
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      a.attribute_id AS "attributeId",
      a.name,
      a.value
    FROM new_attribute a
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
