CREATE OR REPLACE FUNCTION ar.invoice (uuid, OUT result json) AS
$$
BEGIN
  SELECT INTO result
    json_strip_nulls(to_json(r))
  FROM (
    SELECT
      i.*,
      to_char(i.due_date, core.setting('default_date_format')) AS due_date
    FROM ar.invoice_v i
    WHERE i.invoice_uuid = $1
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

CREATE OR REPLACE FUNCTION ar.invoice (json, OUT result json) AS
$$
BEGIN
  result = ar.invoice(($1->>'invoice_uuid')::uuid);
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;