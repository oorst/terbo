CREATE OR REPLACE FUNCTION hucx.save_block (json, OUT result json) AS
$$
BEGIN
  IF $1->>'id' IS NULL THEN
    SELECT hucx.create_element($1) INTO result;
    RETURN;
  ELSE
    WITH saved_block AS (
      UPDATE hucx.block SET (data, modified) = (
        ($1->'data')::jsonb,
        CURRENT_TIMESTAMP
      )
      WHERE block_id = ($1->>'id')::integer
      RETURNING *
    ) SELECT to_json(r) INTO result
    FROM (
      SELECT sb.block_id AS "id", sb.element_id AS "elementId", sb.data
      FROM saved_block sb
    ) r;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
