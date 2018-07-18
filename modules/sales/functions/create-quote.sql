CREATE OR REPLACE FUNCTION sales.create_quote (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      quote."createdBy" AS created_by,
      quote."issuedTo" AS issued_to,
      quote.period,
      quote."contactId" AS contact_id
    FROM json_to_record($1) AS quote (
      "createdBy" integer,
      "issuedTo"  integer,
      period      integer,
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
      li.note,
      li.note_importance
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
      note_importance  li_note_importance_t,
      created          timestamp
    )
  ),
  document AS (
    INSERT INTO sales.source_document (
      issued_to,
      created_by
    )
    SELECT
      issued_to,
      created_by
    FROM payload
    RETURNING *
  ), quote AS (
    INSERT INTO sales.quote (
      document_id,
      expiry_date,
      contact_id
    )
    SELECT
      d.document_id,
      (current_date + COALESCE(p.period, 30))::date AS expiry_date,
      p.contact_id
    FROM document d
    CROSS JOIN payload p
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      document_id AS id,
      status
    FROM document
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
