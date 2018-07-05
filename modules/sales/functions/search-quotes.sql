CREATE OR REPLACE FUNCTION sales.search_quotes (json, OUT result json) AS
$$
BEGIN
  SELECT json_agg(r) INTO result
  FROM (
    SELECT
      quote.document_id AS "id",
      quote.quote_num AS "quoteNumber",
      d.status,
      party_v.name AS "issuedToName"
    FROM sales.source_document d
    INNER JOIN sales.quote
      USING (document_id)
    INNER JOIN party_v
      ON party_v.party_id = d.issued_to
    WHERE strpos(upper(party_v.name), upper($1->>'search')) > 0
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
