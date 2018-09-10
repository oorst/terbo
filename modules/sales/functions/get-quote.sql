CREATE OR REPLACE FUNCTION sales.get_quote (json, OUT result json) AS
$$
BEGIN
  WITH document AS (
    SELECT
      o.order_id,
      o.buyer_id,
      o.created AS order_created,
      o.created_by AS order_created_by,
      o.notes,
      q.quote_id,
      q.status,
      q.data,
      q.contact_id,
      q.issued_at,
      q.expiry_date,
      q.period,
      q.created,
      q.created_by
    FROM sales.order o
    INNER JOIN sales.quote q
      USING (order_id)
    WHERE q.quote_id = ($1->>'quoteId')::integer
  ), line_item AS (
    SELECT
      li.line_item_id AS "lineItemId",
      li.product_id AS "productId",
      li.name,
      li.code,
      li.short_desc AS "shortDescription",
      li.gross,
      li.line_total AS "lineTotal",
      li.quantity
    FROM document
    INNER JOIN sales.line_item_v li
      ON li.order_id = document.order_id
    ORDER BY li.line_position, li.line_item_id ASC
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
      p.phone AS "createdByPhone",
      CASE
        WHEN document.status = 'DRAFT' THEN
          (SELECT json_agg(l) FROM line_item l)
        ELSE document.data::json
      END AS "lineItems",
      (SELECT sum(l."lineTotal") FROM line_item l) AS "total"
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
