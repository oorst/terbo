CREATE OR REPLACE FUNCTION sales.get_invoice (integer, OUT result json) AS
$$
BEGIN
  WITH document AS (
    SELECT
      o.order_id,
      o.created_by AS order_created_by,
      o.purchase_order_num,
      o.buyer_id,
      i.status,
      i.contact_id,
      i.invoice_id,
      i.issued_at,
      i.due_date,
      i.period,
      i.notes,
      i.created,
      i.created_by
    FROM sales.order o
    INNER JOIN sales.invoice i
      USING (order_id)
    -- INNER JOIN person creator
    --   ON creator.party_id = i.created_by
    WHERE i.invoice_id = $1
  ), line_item AS (
    SELECT
      li.line_item_id AS "lineItemId",
      li.order_id AS "orderId",
      li.product_id AS "productId",
      li.position,
      coalesce(li.code, p._code) AS code,
      coalesce(li.name, p._name) AS name,
      coalesce(li.description, p._description) AS description,
      uom.name AS "uomName",
      uom.abbr AS "uomAbbr",
      li.data,
      li.quantity,
      coalesce(li.gross, price.gross) AS gross,
      (coalesce(li.gross, price.gross) * coalesce(li.quantity, 1.000))::numeric(10,2) AS "lineTotal"
    FROM sales.line_item li
    INNER JOIN document
      USING (order_id)
    LEFT JOIN prd.product_list_v p
      USING (product_id)
    LEFT JOIN prd.price_v price
      ON price.product_id = li.product_id
    LEFT JOIN prd.product pp
      ON pp.product_id = li.product_id
    LEFT JOIN prd.uom uom
      ON uom.uom_id = pp.uom_id
    WHERE document.invoice_id = $1
    ORDER BY position, line_item_id
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      document.order_id AS "orderId",
      document.invoice_id AS "invoiceId",
      buyer.name AS "buyerName",
      buyer.type AS "buyerType",
      document.purchase_order_num AS "purchaseOrderNumber",
      document.status,
      document.created::date AS "createdDate",
      document.issued_at::date AS "issueDate",
      document.due_date AS "dueDate",
      document.period,
      document.notes,
      coalesce(contactPerson.name, contact.name) AS "issuedToContactName",
      contactPerson.email AS "issuedToContactEmail",
      creator.name AS "createdByName",
      creator.email AS "createdByEmail",
      creator.mobile AS "createdByMobile",
      creator.phone AS "createdByPhone",
      (SELECT json_agg(l) FROM line_item l) AS "lineItems"
    FROM document
    INNER JOIN party_v buyer
      ON buyer.party_id = document.buyer_id
    LEFT JOIN party_v contact
      ON contact.party_id = document.contact_id
    LEFT JOIN person contactPerson
      ON contactPerson.party_id = document.contact_id
    INNER JOIN person creator
      ON creator.party_id = document.created_by
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sales.get_invoice (json, OUT result json) AS
$$
BEGIN
  SELECT sales.get_invoice(($1->>'invoiceId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
