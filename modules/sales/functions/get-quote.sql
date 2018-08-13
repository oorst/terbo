CREATE OR REPLACE FUNCTION sales.get_quote (integer, OUT result json) AS
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
    WHERE q.order_id = $1
  ), line_item AS (
    SELECT
      li.line_item_id AS "lineItemId",
      li.product_id AS "productId",
      li.position,
      coalesce(li.code, p._code) AS code,
      coalesce(li.name, p._name) AS name,
      coalesce(li.description, p._description) AS description,
      uom.name AS "uomName",
      uom.abbr AS "uomAbbr",
      li.data,
      li.quantity,
      li.gross,
      coalesce(li.gross, prd.product_gross(p.product_id)) AS "$gross"
    FROM sales.line_item li
    LEFT JOIN prd.product_list_v p
      USING (product_id)
    LEFT JOIN prd.product pp
      ON pp.product_id = li.product_id
    LEFT JOIN prd.uom uom
      ON uom.uom_id = pp.uom_id
    WHERE li.quote_id = $1
    ORDER BY position, line_item_id
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
      (SELECT json_agg(l) FROM line_item l) AS "lineItems"
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
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sales.get_quote (json, OUT result json) AS
$$
BEGIN
  SELECT
    sales.get_quote(q.quote_id) INTO result
  FROM sales.quote q
  WHERE q.quote_id = ($1->>'quoteId')::integer;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

COMMENT ON FUNCTION sales.get_quote(integer) IS 'This function replaced replaced by the Massey Schema';
