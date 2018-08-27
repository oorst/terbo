CREATE OR REPLACE FUNCTION get_organisation (id integer, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      party_id AS "partyId",
      name,
      trading_name AS "tradingName",
      url,
      data,
      a.addr1,
      a.addr2,
      a.town,
      a.state,
      a.code,
      party.type
    FROM organisation
    INNER JOIN party
      USING (party_id)
    LEFT JOIN address a
      USING (address_id)
    WHERE party_id = id
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_organisation (json, OUT result json) AS
$$
BEGIN
  SELECT get_organisation(($1->>'id')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
