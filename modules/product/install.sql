\echo 'Installing Product schema...'
\ir schema.sql
\echo 'Installing Product functions...'
\ir functions/index.sql

\echo 'Installing Product Basics...'
INSERT INTO prd.uom (name, abbr, type) VALUES
  ('Metre', 'm', 'length'),
  ('Kilogram', 'kg', 'mass'),
  ('Square metre', 'sqm', 'area'),
  ('Cubic metre', 'cbm', 'volume');
