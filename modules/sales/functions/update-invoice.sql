CREATE OR REPLACE FUNCTION sales._update_invoice (integer, OUT result json) AS
$$
BEGIN
  UPDATE sales.invoice
  SET balance = (
    SELECT SUM(l.price)
    FROM sales.invoice_line l
    WHERE l.invoice_id = $1
  )
  WHERE invoice_id = $1;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
