\echo 'Installing Product schema...'
\ir schema.sql
\echo 'Installing Product functions...'
\ir functions/index.sql

\echo 'Installing Product Basics...'
INSERT INTO prd.uom (name, abbr, type) VALUES
  ('Metre', 'm', 'length'), -- 1
  ('Kilogram', 'kg', 'mass'), -- 2
  ('Square metre', 'sqm', 'area'), -- 3
  ('Cubic metre', 'cbm', 'volume'); -- 4
