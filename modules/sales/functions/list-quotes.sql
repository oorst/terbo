CREATE OR REPLACE FUNCTION sales.list_quotes (json, OUT result json) AS
$$
BEGIN
  -- Throw if no search term is present
  IF $1->>'search' IS NULL THEN
    RAISE EXCEPTION 'no search term provided';
  END IF;

  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      q.order_id AS "orderId",
      q.quote_id AS "quoteId",
      q.status,
      q.issued_at AS "issuedAt",
      buyer.name AS "issuedToName",
      buyer.party_id AS "issuedToId",
      contact.name AS "contactName",
      contact.party_id AS "contactId",
      q.created
    FROM sales.quote q
    INNER JOIN sales.order o
      USING (order_id)
    INNER JOIN party_v buyer
      ON buyer.party_id = o.buyer_id
    LEFT JOIN party_v contact -- Left join as a document may not have a contact
      ON contact.party_id = q.contact_id
    WHERE to_tsvector(
      concat_ws(' ',
        q.order_id,
        buyer.name,
        contact.name
      )
    ) @@ plainto_tsquery($1->>'search')
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
