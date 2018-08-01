CREATE OR REPLACE FUNCTION sales.list_purchase_orders (json, OUT result json) AS
$$
BEGIN
  -- Throw if no search term is present
  IF $1->>'search' IS NULL THEN
    RAISE EXCEPTION 'no search term provided';
  END IF;

  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      po.document_id AS "documentId",
      d.status,
      po.issued_at AS "issuedAt",
      party_v.name AS "issuedToName",
      party_v.party_id AS "issuedToId",
      contact.name AS "contactName",
      contact.party_id AS "contactId"
    FROM sales.purchase_order po
    INNER JOIN sales.source_document d
      USING (document_id)
    INNER JOIN party_v
      ON party_v.party_id = d.issued_to
    LEFT JOIN party_v contact -- Left join as a document may not have a contact
      ON contact.party_id = d.contact_id
    WHERE to_tsvector(
      concat_ws(' ',
        party_v.name,
        contact.name
      )
    ) @@ plainto_tsquery($1->>'search')
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
