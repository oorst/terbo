CREATE OR REPLACE FUNCTION sales.quote (json, OUT result json) AS
$$
BEGIN
  WITH document AS (
    SELECT
      o.order_id,
      o.buyer_id,
      o.created AS order_created,
      o.created_by AS order_created_by,
      q.quote_id,
      q.status,
      q.contact_id,
      q.issued_at,
      q.expiry_date,
      q.period,
      q.notes,
      q.created,
      q.created_by
    FROM sales.order o
    INNER JOIN sales.quote q
      USING (order_id)
    WHERE q.quote_id = ($1->>'quoteId')::integer
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      document.order_id AS "orderId",
      document.quote_id AS "quoteId",
      buyer.name AS "buyerName",
      buyer.type AS "buyerType",
      document.order_created AS "orderCreated",
      document.order_created_by AS "orderCreatedBy",
      document.status,
      document.created::date AS "createdDate",
      document.issued_at::date AS "issueDate",
      document.expiry_date AS "expiryDate",
      document.period,
      document.notes,
      coalesce(contactPerson.name, contact.name) AS "issuedToContactName",
      contactPerson.email AS "issuedToContactEmail",
      p.name AS "createdByName",
      p.email AS "createdByEmail",
      p.mobile AS "createdByMobile",
      p.phone AS "createdByPhone"
    FROM document
    INNER JOIN party_v buyer
      ON buyer.party_id = document.buyer_id
    LEFT JOIN party_v contact
      ON contact.party_id = document.contact_id
    LEFT JOIN person contactPerson
      ON contactPerson.party_id = document.contact_id
    INNER JOIN person p
      ON p.party_id = document.created_by
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
