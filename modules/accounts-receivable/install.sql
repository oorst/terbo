--
-- Core inserts
--

INSERT INTO core.document_kind (name) VALUES ('invoice'),('receipt');
INSERT INTO core.document_origin (name) VALUES ('accounts_receivable');

\ir schema.sql
\ir functions/index.sql