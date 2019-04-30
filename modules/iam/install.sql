\echo 'Installing IAM schema...'
\ir schema.sql
\echo 'Done...'
\echo 'Installing IAM functions...'
\ir functions/index.sql
\echo 'Done...'