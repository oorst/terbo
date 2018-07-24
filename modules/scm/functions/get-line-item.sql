CREATE OR REPLACE FUNCTION scm.get_line_item (uuid, OUT result json) AS
$$
BEGIN
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      i.item_uuid AS uuid,
      i."$name",
      i.sku,
      i."$code",
      i."$description",
      (
        SELECT sum(line_total) FROM scm.item_boq($1)
      ) AS gross
    FROM scm.item_list_v i
    WHERE item_uuid = $1
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION scm.get_line_item (json, OUT result json) AS
$$
BEGIN
  IF $1->>'uuid' IS NULL THEN
    RAISE EXCEPTION 'must provide a uuid';
  END IF;

  IF json_typeof($1->'uuid') = 'array' THEN
    WITH payload AS (
      SELECT
        value::uuid AS uuid
      FROM json_array_elements_text($1->'uuid')
    )
    SELECT json_agg(scm.get_line_item(uuid)) INTO result
    FROM payload;
  ELSE
    SELECT scm.get_line_item(($1->>'uuid')::uuid) INTO result;
  END IF;
END
$$
LANGUAGE 'plpgsql';
