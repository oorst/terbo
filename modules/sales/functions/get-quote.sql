CREATE OR REPLACE FUNCTION sales.get_quote (integer, OUT result json) AS
$$
BEGIN
  WITH line_items AS (
    SELECT *
    FROM sales.line_item
    WHERE document_id = $1
  ), document AS (
    SELECT
      d.document_id,
      d.status,
      q.expiry_date,
      d.issued_to,
      q.period
    FROM sales.source_document d
    INNER JOIN sales.quote q
      USING (document_id)
    WHERE d.document_id = $1
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      document.document_id AS id,
      party_v.name AS "issuedToName",
      document.status,
      document.expiry_date AS "expiryDate",
      document.period
    FROM document
    INNER JOIN party_v
      ON party_v.party_id = document.issued_to
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sales.get_quote (json, OUT result json) AS
$$
BEGIN
  SELECT
    sales.get_quote(q.document_id) INTO result
  FROM sales.quote q
  WHERE q.document_id = ($1->>'id')::integer OR q.quote_num = $1->>'quoteNum';
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
