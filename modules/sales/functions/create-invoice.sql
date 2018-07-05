CREATE OR REPLACE FUNCTION sales.create_invoice (json, OUT result json) AS
$$
DECLARE
  _invoice_id integer;
BEGIN
  SELECT invoice_id INTO _invoice_id
  FROM (
    INSERT INTO sales.invoice (
    customer_account_id
    ) values (
      ($1->>'customerId')::integer
    ) RETURNING invoice_id
  );

  -- If there's any line data, insert it here
  IF $1->>'lines' IS NOT NULL THEN
    FOR i IN SELECT * FROM json_array_elements($1->'lines')
    LOOP
      INSERT INTO sales.invoice_line (
        invoice_id,
        price
      ) values (
        _invoice_id,
        (i->>'price')::numeric
      )
    END LOOP;

    -- Update
    SELECT sales._update_invoice(_invoice_id) INTO result;
  ELSE
    -- Just return the new empty invloice
    SELECT to_json(r) INTO result
    FROM (
      SELECT *
      FROM sales.invoice i
      WHERE i.invoice_id = _invoice_id;
    ) r;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
