CREATE OR REPLACE FUNCTION sales.list_invoices (OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      i.invoice_id AS "invoiceId",
      recipient.name AS "recipientName",
      NULLIF(
        (
          (i.payment_status = 'OWING') AND (i.due_date < CURRENT_TIMESTAMP)
        ),
        FALSE
      ) AS overdue
    FROM sales.invoice i
    LEFT JOIN party_v recipient
      ON recipient.party_id = i.recipient_id
    LIMIT 20
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

CREATE OR REPLACE FUNCTION sales.list_invoices (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      o.order_id AS "orderId",
      o.status AS "orderStatus",
      buyer.name AS "buyerName",
      i.invoice_id AS "invoiceId",
      i.issued_at AS "issuedAt",
      contact.name AS "contactName",
      contact.party_id AS "contactId"
    FROM sales.order o
    INNER JOIN sales.invoice i
      USING (order_id)
    INNER JOIN party_v buyer
      ON buyer.party_id = o.buyer_id
    LEFT JOIN party_v contact -- Left join as a document may not have a contact
      ON contact.party_id = i.contact_id
    WHERE o.order_id = ($1->>'orderId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
