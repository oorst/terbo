CREATE OR REPLACE FUNCTION core.create_organisation (json, OUT result json) AS
$$
DECLARE
  new_org_uuid uuid;
BEGIN
  WITH payload AS (
    SELECT
      p.*
    FROM json_to_record($1) AS p (
      name         text,
      kind         core.party_kind_t,
      trading_name text,
      data         jsonb
    )
  ), new_party AS (
    INSERT INTO core.party (
      name,
      kind,
      tsv,
      data
    )
    SELECT
      p.name,
      p.kind,
      setweight(to_tsvector('simple', p.name), 'A') ||
        setweight(to_tsvector('simple', COALESCE(p.trading_name, '')), 'A'),
      p.data
    FROM payload p 
    RETURNING *
  )
  INSERT INTO core.organisation (
    party_uuid,
    trading_name
  )
  SELECT
    (SELECT party_uuid FROM new_party),
    p.trading_name
  FROM payload p
  RETURNING party_uuid INTO new_org_uuid;
  
  SELECT core.organisation(new_org_uuid) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
