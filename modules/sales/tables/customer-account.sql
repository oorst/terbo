CREATE TABLE sales.customer_account (
  account_id      serial PRIMARY KEY,
  part_id         REFERENCES party (party_id),
  created         timestamp DEFAULT CURRENT_TIMESTAMP
);
