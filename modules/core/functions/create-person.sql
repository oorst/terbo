CREATE OR REPLACE FUNCTION core.create_person (json, OUT result json) AS
$$
DECLARE
  new_person_uuid uuid;
BEGIN
  WITH payload AS (
    SELECT
      p.*
    FROM json_to_record($1) AS p (
      kind       core.party_kind_t,
      name       text,
      email      text,
      mobile     text,
      phone      text
    )
  ), new_party AS (
    INSERT INTO core.party (
      name,
      kind,
      tsv
    )
    SELECT
      p.name,
      p.kind,
      setweight(to_tsvector('simple', p.name), 'B') ||
        setweight(to_tsvector('simple', p.email), 'A')
    FROM payload p 
    RETURNING *
  )
  INSERT INTO core.person (
    party_uuid,
    email,
    mobile,
    phone
  )
  SELECT
    (SELECT party_uuid FROM new_party),
    p.email,
    p.mobile,
    p.phone
  FROM payload p
  RETURNING party_uuid INTO new_person_uuid;
  
  SELECT core.person(new_person_uuid) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
