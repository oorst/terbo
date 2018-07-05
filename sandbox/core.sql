\c massey_test
DROP DATABASE test14;
CREATE DATABASE test14;
\c test14
\i /users/mattandrews/devs/terbo/modules/core/install.sql

INSERT INTO person (name) values ('jambo');
