\echo 'Installing Core schema...'
\ir schema.sql
\echo 'Done...'
\echo 'Installing Core functions...'
\ir functions/index.sql
\echo 'Done...'

\echo 'Insert core settings...'
INSERT INTO core.setting (name, value) VALUES
  ('default_date_format', 'FMDD Mon YYYY');