CREATE OR REPLACE FUNCTION search_organisation (text) RETURNS json AS
$$
DECLARE

  searchTerm text;
  result json;

BEGIN

  searchTerm = $1 || '%';

  SELECT json_agg(search) INTO result
  FROM (SELECT o.name, o.abn, e.entity_id AS id
        FROM organisation o
        INNER JOIN entity e USING (organisation_id)
        WHERE name ILIKE searchTerm) as search;

  RETURN result;

END
$$
LANGUAGE 'plpgsql';
