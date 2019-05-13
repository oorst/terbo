CREATE OR REPLACE FUNCTION core.create_organisation (json, OUT result json) AS
$$
DECLARE
  new_org_uuid uuid;
BEGIN
  INSERT INTO core.organisation (
    name,
    trading_name,
    url
  )
  SELECT
    p.name,
    p.trading_name,
    p.url
  FROM json_to_record($1) AS p (
    name          text,
    trading_name  text,
    url           text
  )
  RETURNING party_uuid INTO new_org_uuid;
  
  SELECT
    json_strip_nulls(to_json(core.party(new_org_uuid)))
  INTO
    result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
