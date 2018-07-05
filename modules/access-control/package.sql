CREATE SCHEMA access_control;

\ir tables/identity.sql
\ir tables/role.sql
\ir tables/permission.sql
\ir tables/resource.sql
\ir tables/reset-token.sql
\ir tables/role-permission.sql
\ir tables/resource-permission.sql

\ir functions/check-reset-token.sql
\ir functions/generate-password-reset-token.sql
