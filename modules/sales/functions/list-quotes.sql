CREATE OR REPLACE FUNCTION sales.list_quotes (json, OUT result json) AS
$$
BEGIN
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
      q.created,
      CASE
        WHEN q.created < o.modified THEN TRUE
        ELSE NULL
      END AS outdated
    FROM sales.quote q
    INNER JOIN sales.order o
      USING (order_id)
    INNER JOIN json_to_record($1) AS j (
      "orderId" integer
    ) ON j."orderId" = o.order_id
    LEFT JOIN party_v buyer
      ON buyer.party_id = o.buyer_id
    LEFT JOIN party_v contact -- Left join as a document may not have a contact
      ON contact.party_id = q.contact_id
    ORDER BY q.quote_id DESC
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
