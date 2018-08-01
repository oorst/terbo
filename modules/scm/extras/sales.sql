/*
Sales

Allows Items to appear on sales documents.
*/

-- Add an item_uuid column to sales.line_item.  Note this does not point to an
-- item instance.
ALTER TABLE sales.line_item ADD COLUMN item_uuid uuid REFERENCES scm.item (item_uuid);

-- The following function replaces the sales.get_quote and calculates the
-- gross price where a sales.line_item points to an scm.item
CREATE OR REPLACE FUNCTION sales.get_document (integer, OUT result json) AS
$$
BEGIN
  WITH document AS (
    SELECT
      d.document_id,
      d.status,
      d.issued_to,
      d.created_by,
      d.contact_id,
      CASE
        WHEN q IS NULL THEN i.issued_at
        ELSE q.issued_at
      END AS issued_at,
      CASE
        WHEN q IS NULL THEN i.due_date
        ELSE NULL
      END AS due_date,
      CASE
        WHEN q IS NULL THEN NULL
        ELSE q.expiry_date
      END AS expiry_date,
      CASE
        WHEN q IS NULL THEN i.period
        ELSE q.period
      END AS period,
      CASE
        WHEN q IS NULL THEN i.notes
        ELSE q.notes
      END AS notes,
      CASE
        WHEN q IS NULL THEN i.created
        ELSE q.created
      END AS created,
      CASE
        WHEN q IS NULL THEN 'INVOICE'
        ELSE 'QUOTE'
      END AS document_type
    FROM sales.source_document d
    INNER JOIN person prsn
      ON prsn.party_id = d.created_by
    LEFT JOIN sales.quote q
      ON q.document_id = d.document_id
    LEFT JOIN sales.invoice i
      ON i.document_id = d.document_id
    WHERE d.document_id = $1
  ), line_item AS (
    SELECT
      li.line_item_id AS "lineItemId",
      li.document_id AS "documentId",
      li.product_id AS "productId",
      li.item_uuid AS "itemUuid",
      li.position,
      coalesce(li.code, p._code) AS code,
      coalesce(li.name, i.name, p._name) AS name,
      coalesce(li.description, p._description) AS description,
      uom.name AS "uomName",
      uom.abbr AS "uomAbbr",
      li.data,
      li.quantity,
      li.gross,
      CASE
        WHEN document.status = 'DRAFT' AND li.item_uuid IS NOT NULL THEN
          coalesce(li.gross, (SELECT sum(line_total) FROM scm.item_boq(li.item_uuid)))
        WHEN document.status = 'DRAFT' THEN
          coalesce(li.gross, prd.product_gross(p.product_id))
        ELSE li.gross
      END AS "$gross"
    FROM document
    INNER JOIN sales.line_item li
      USING (document_id)
    LEFT JOIN prd.product_list_v p
      USING (product_id)
    LEFT JOIN scm.item i
      USING (item_uuid)
    LEFT JOIN prd.product pp
      ON pp.product_id = li.product_id
    LEFT JOIN prd.uom uom
      ON uom.uom_id = pp.uom_id
    ORDER BY position, line_item_id
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      document.document_id AS "documentId",
      document.document_type AS "documentType",
      party_v.name AS "issuedToName",
      party_v.type AS "issuedToType",
      document.status,
      document.created::date AS "createdDate",
      document.issued_at::date AS "issueDate",
      document.expiry_date AS "expiryDate",
      document.due_date AS "dueDate",
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

CREATE OR REPLACE FUNCTION sales.issue_quote (json, OUT result json) AS
$$
BEGIN
  IF $1->>'documentId' IS NULL THEN
    RAISE EXCEPTION 'must provide documentId to issue quote';
  END IF;

  -- Ensure that the line_item_gross is set where line_items point to
  -- scm.item
  UPDATE sales.line_item li SET gross = (SELECT sum(line_total) FROM scm.item_boq(li.item_uuid))
  WHERE li.document_id = ($1->>'documentId')::integer AND li.item_uuid IS NOT NULL;

  UPDATE sales.quote_v q SET (
    issued_at,
    status,
    expiry_date
  ) = (
    CURRENT_TIMESTAMP,
    'ISSUED',
    (CURRENT_TIMESTAMP + (INTERVAL '1 day') * q.period)::date
  )
  WHERE q.document_id = ($1->>'documentId')::integer;

  SELECT sales.get_quote(($1->>'documentId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

CREATE OR REPLACE FUNCTION sales.issue_invoice (json, OUT result json) AS
$$
BEGIN
  IF $1->>'documentId' IS NULL THEN
    RAISE EXCEPTION 'must provide documentId to issue invoice';
  END IF;

  -- Ensure that the line_item_gross is set where line_items point to
  -- scm.item
  UPDATE sales.line_item li SET (
    gross
  ) = (
    CASE
      WHEN li.gross IS NULL AND li.item_uuid IS NOT NULL THEN
        (SELECT sum(line_total) FROM scm.item_boq(li.item_uuid))
      WHEN li.gross IS NULL THEN
         prd.product_gross(li.product_id)
      ELSE li.gross
    END
  )
  WHERE li.document_id = ($1->>'documentId')::integer;

  UPDATE sales.invoice_v i SET (
    issued_at,
    status,
    due_date
  ) = (
    CURRENT_TIMESTAMP,
    'ISSUED',
    (CURRENT_TIMESTAMP + (INTERVAL '1 day') * i.period)::date
  )
  WHERE i.document_id = ($1->>'documentId')::integer;

  SELECT sales.get_invoice(($1->>'documentId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

-- Create line items within the sales schema that point to scm.items
CREATE OR REPLACE FUNCTION scm.create_line_item (json, OUT result json) AS
$$
BEGIN
  IF json_typeof($1) = 'array' THEN
    SELECT json_agg(scm.create_line_item(value)) INTO result
    FROM json_array_elements($1);
  ELSE
    IF $1->>'documentId' IS NULL THEN
      RAISE EXCEPTION 'must provide documentId to create line item';
    END IF;

    WITH payload AS (
      SELECT
        j."documentId" AS document_id,
        j."itemUuid" AS item_uuid
      FROM json_to_record($1) AS j (
        "documentId" integer,
        "itemUuid"   uuid
      )
    ), line_item AS (
      INSERT INTO sales.line_item (
        document_id,
        item_uuid,
        product_id
      )
      SELECT
        p.document_id,
        p.item_uuid,
        i.product_id
      FROM payload p
      INNER JOIN scm.item i
        USING (item_uuid)
      RETURNING *
    )
    SELECT json_strip_nulls(to_json(r)) INTO result
    FROM (
      SELECT
        line_item_id AS "lineItemId",
        document_id AS "documentId",
        item_uuid AS "itemUuid",
        product_id AS "productId"
      FROM line_item
    ) r;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
