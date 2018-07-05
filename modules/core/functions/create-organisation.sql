CREATE OR REPLACE FUNCTION create_organisation (json, OUT result json) AS
$$
BEGIN
  WITH new_organisation AS (
    INSERT INTO organisation (
      name,
      url,
      data,
      address
    ) VALUES (
      $1->>'name',
      $1->>'url',
      $1->'data',
      CASE
        WHEN $1->'address' IS NOT NULL THEN
          (
            SELECT address_id
            FROM insert_address($1->'address')
          )
        ELSE NULL
      END
    )
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      party_id AS id
    FROM new_organisation
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
