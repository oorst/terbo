CREATE OR REPLACE FUNCTION sales.get_customer_by_account_id (json, OUT result json) AS
$$
DECLARE
  _person_id       integer;
  _organisation_id integer;
BEGIN
  SELECT person_id INTO _person_id,
    organisation_id INTO _organisation_id
  FROM sales.customer_account
  WHERE account_id = ($1->>'id')::integer;

  IF _person_id IS NOT NULL THEN
    SELECT get_person(_person_id) INTO result;
  ELSE
    SELECT get_organisation(_organisation_id) INTO result;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
