CREATE TYPE invoice_status_t AS ENUM ('draft', 'dispatched');

CREATE TABLE sales.invoice (
  invoice_id          serial PRIMARY KEY,
  customer_account_id integer REFERENCES sales.customer_account (account_id),
  bits                integer,
  current_balance     numeric(10,2),
  due_date            timestamp,  -- Local time
  status              invoice_status_t,
  iat                 timestamp DEFAULT CURRENT_TIMESTAMP, -- Issued at
  created             timestamp DEFAULT CURRENT_TIMESTAMP
);
