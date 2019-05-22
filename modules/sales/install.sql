--
-- Core inserts
--

INSERT INTO core.document_kind (name) VALUES ('quote');
INSERT INTO core.document_origin (name) VALUES ('sales');

\echo 'Installing Sales schema...'
\ir schema.sql
\echo 'Installing Sales functions...'
\ir functions/index.sql
