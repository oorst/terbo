CREATE OR REPLACE FUNCTION search_person (text) RETURNS json AS
$$
DECLARE

  searchTerm text;
  result json;

BEGIN

  searchTerm = $1 || '%';

  SELECT json_agg(search) INTO result
  FROM (SELECT p.email, p.name, e.entity_id AS id
        FROM person p
        INNER JOIN entity e USING (person_id)
        WHERE p.email LIKE searchTerm) as search;

  RETURN result;

END
$$
LANGUAGE 'plpgsql';
