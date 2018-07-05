CREATE TABLE scm.bom_line (
  bom_line_id serial PRIMARY KEY,
  bom_id      integer REFERENCES man.bom (bom_id),
  product_id  integer REFERENCES prd.product (product_id),
  qty         numeric(10,3),
  created     timestamp (0) DEFAULT CURRENT_TIMESTAMP
)
