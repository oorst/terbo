/**
@function
  This function only updates fields that have an existant corresponding key/value
  in the JSON payload.

  If you want to set a field to NULL then set the corresponding field to `null`
  in the JSON payload.

  When cost or pricing is included a new cost and/or price record is created to
  maintain a history.

  @def prd.update_product (json)
  @returns {json}
  @api
*/
CREATE OR REPLACE FUNCTION core.update_organisation (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE core.organisation SET (%s) = (%s) WHERE party_uuid = ''%s''', c.column, c.value, c.party_uuid)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'party_uuid')::uuid AS party_uuid
      FROM (
        SELECT
          p.key AS column,
          CASE
            -- check if it's a number
            WHEN p.value ~ '^\d+(.\d+)?$' THEN
              p.value
            WHEN p.value IS NULL THEN
              'NULL'
            ELSE quote_literal(p.value)
          END AS value
        FROM json_each_text($1) p
        WHERE p.key != 'party_uuid' AND p.key != 'type'
      ) q
    ) c
  );

  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      *
    FROM core.organisation o
    WHERE o.party_uuid = ($1->>'party_uuid')::uuid
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
