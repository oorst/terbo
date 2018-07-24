CREATE OR REPLACE FUNCTION sales.create_invoice (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      quote."createdBy" AS created_by,
      quote."issuedTo" AS issued_to,
      quote."contactId" AS contact_id
    FROM json_to_record($1) AS quote (
      "createdBy" integer,
      "issuedTo"  integer,
      "contactId" integer
    )
  ),
  line_item AS (
    SELECT
      li.code,
      li.name,
      li.description,
      li.data,
      li."discountPc" AS discount_pc,
      li."discountAmount" AS discount_amt,
      li.gross,
      li.net,
      li."uomId" AS uom_id,
      li.quantity,
      li.tax,
      li.note
    FROM json_to_recordset($1->'lineItems') AS li (
      code             text,
      name             text,
      description      text,
      data             jsonb,
      "discountPc"     numeric(3,2),
      "discountAmount" numeric(10,2),
      gross            numeric(10,2),
      net              numeric(10,2),
      "uomId"          integer,
      quantity         numeric(10,3),
      tax              boolean,
      note             text,
      created          timestamp
    )
  ),
  document AS (
    INSERT INTO sales.source_document (
      issued_to,
      contact_id,
      created_by
    )
    SELECT
      issued_to,
      contact_id,
      created_by
    FROM payload
    RETURNING *
  ), invoice AS (
    INSERT INTO sales.invoice (
      document_id,
      due_date
    )
    SELECT
      d.document_id,
      (current_date + 30)::date AS expiry_date
    FROM document d
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      document_id AS "invoiceId",
      status
    FROM document
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
