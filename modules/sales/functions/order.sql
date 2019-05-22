CREATE OR REPLACE FUNCTION sales.order (uuid, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      o.order_uuid,
      o.invoice_uuid,
      i.document_num AS invoice_document_num,
      o.customer_uuid,
      o.contact_uuid,
      o.status,
      o.data,
      o.short_desc,
      o.created,
      cst.name AS customer_name,
      cnt.name AS contact_name
    FROM sales.order o
    LEFT JOIN ar.invoice_v i
      ON i.invoice_uuid = o.invoice_uuid
    LEFT JOIN core.party cst
      ON cst.party_uuid = o.customer_uuid
    LEFT JOIN core.party cnt
      ON cnt.party_uuid = o.contact_uuid
    WHERE o.order_uuid = $1
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sales.order (json, OUT result json) AS
$$
BEGIN
  SELECT sales.order(($1->>'order_uuid')::uuid) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
