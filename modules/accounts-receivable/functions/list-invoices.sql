CREATE OR REPLACE FUNCTION ar.list_invoices (OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      i.invoice_uuid,
      i.issuance_status,
      d.document_num,
      d.approval_status,
      payor.party_uuid AS payor_uuid,
      payor.name AS payor_name,
      contact.party_uuid AS contact_uuid,
      contact.name
    FROM ar.invoice i
    INNER JOIN core.document d
      ON d.document_uuid = i.invoice_uuid
    LEFT JOIN core.party payor
      ON payor.party_uuid = i.payor_uuid
    LEFT JOIN core.party contact
      ON contact.party_uuid = i.contact_uuid
    LIMIT 20
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
