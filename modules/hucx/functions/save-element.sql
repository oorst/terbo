CREATE OR REPLACE FUNCTION hucx.save_element (json, OUT result json) AS
$$
BEGIN
  IF $1->>'id' IS NULL THEN
    SELECT hucx.create_element($1) INTO result;
    RETURN;
  ELSE
    WITH saved_element AS (
      UPDATE hucx.element SET (data, modified) = (
        ($1->'data')::jsonb,
        CURRENT_TIMESTAMP
      )
      WHERE element_id = ($1->>'id')::integer
      RETURNING *
    ) SELECT to_json(r) INTO result
    FROM (
      SELECT se.element_id AS "id", data
      FROM saved_element se
    ) r;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
