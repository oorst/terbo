CREATE OR REPLACE FUNCTION create_person (json, OUT result json) AS
$$
BEGIN
  WITH new_person AS (
    INSERT INTO person (
      name,
      email,
      mobile,
      phone,
      address
    ) values (
      $1->>'name',
      $1->>'email',
      $1->>'mobile',
      $1->>'phone',
      CASE
        WHEN $1->'address' IS NOT NULL THEN
          (
            SELECT address_id
            FROM insert_address($1->'address')
          )
        ELSE NULL
      END
    ) RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      party_id AS id,
      name,
      email,
      mobile,
      phone
    FROM new_person
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
