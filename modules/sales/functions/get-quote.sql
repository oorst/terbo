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
      d.issued_to,
      d.created_by,
      q.contact_id,
      q.expiry_date,
      q.period
    FROM sales.source_document d
    INNER JOIN person prsn
      ON prsn.party_id = d.created_by
    INNER JOIN sales.quote q
      USING (document_id)
    WHERE d.document_id = $1
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      document.document_id AS id,
      coalesce(party_v.trading_name, party_v.name) AS "issuedToName",
      document.status,
      document.expiry_date AS "expiryDate",
      document.period,
      contact.name AS "issuedToContactName",
      p.name AS "createdByName",
      p.email AS "createdByEmail",
      p.mobile AS "createdByMobile",
      p.phone AS "createdByPhone"
    FROM document
    INNER JOIN party_v
      ON party_v.party_id = document.issued_to
    LEFT JOIN party_v contact
      ON contact.party_id = document.contact_id
    INNER JOIN person p
      ON p.party_id = document.created_by
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
