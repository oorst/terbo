CREATE OR REPLACE FUNCTION sales.get_purchase_order (integer, OUT result json) AS
$$
BEGIN
  WITH document AS (
    SELECT
      d.document_id,
      d.status,
      d.issued_to,
      d.created_by,
      d.contact_id,
      po.issued_at,
      po.notes,
      d.created
    FROM sales.source_document d
    INNER JOIN sales.purchase_order po
      USING (document_id)
    WHERE d.document_id = $1
  ), line_item AS (
    SELECT
      li.line_item_id AS "lineItemId",
      li.document_id AS "documentId",
      li.product_id AS "productId",
      li.position,
      coalesce(li.code, p._code) AS code,
      coalesce(li.name, p._name) AS name,
      coalesce(li.description, p._description) AS description,
      uom.name AS "uomName",
      uom.abbr AS "uomAbbr",
      li.data,
      li.quantity
    FROM sales.line_item li
    LEFT JOIN prd.product_list_v p
      USING (product_id)
    LEFT JOIN prd.product pp
      ON pp.product_id = li.product_id
    LEFT JOIN prd.uom uom
      ON uom.uom_id = pp.uom_id
    WHERE document_id = $1
    ORDER BY position, line_item_id
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      document.document_id AS "documentId",
      party_v.name AS "issuedToName",
      party_v.type AS "issuedToType",
      document.status,
      document.created::date AS "createdDate",
      document.issued_at::date AS "issueDate",
      document.notes,
      coalesce(contactPerson.name, contact.name) AS "issuedToContactName",
      contactPerson.email AS "issuedToContactEmail",
      p.name AS "createdByName",
      p.email AS "createdByEmail",
      p.mobile AS "createdByMobile",
      p.phone AS "createdByPhone",
      (SELECT json_agg(l) FROM line_item l) AS "lineItems"
    FROM document
    INNER JOIN party_v
      ON party_v.party_id = document.issued_to
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

CREATE OR REPLACE FUNCTION sales.get_purchase_order (json, OUT result json) AS
$$
BEGIN
  SELECT
    sales.get_purchase_order(po.document_id) INTO result
  FROM sales.purchase_order po
  WHERE po.document_id = ($1->>'documentId')::integer;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
