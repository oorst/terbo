CREATE TABLE sales.inv_line (
  inv_line_id serial PRIMARY KEY,
  invoice_id  REFERENCES sales.invoice (invoice_id) ON DELETE CASCADE,
  identifier  text,
  description text,
  sub_desc    text,
  price       numeric(10,2),
  quantity    integer,
  uom         text,
  created     timestamp CURRENT_TIMESTAMP
);
