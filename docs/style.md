# Style Guide

- No nested views
- No CTEs in views
- Use CTEs in functions
- API implemented through functions

### Function Naming Conventions

Generally, each table has corresponding CRUD functions, that is each table has
create, read, update and delete functions. The four functions are named as
follows:

- <schema name>.create_<table name>(json)
- <schema name>.<table name>(json)
- <schema name>.update_<table name>(json)
- <schema name>.delete_<table name>(json)

Notice that that the read function forgoes the word `read` at the beginning
of the function name.

#### Read Functions

Read functions generally return all fields of the requested record. Where a
references a foreign key, the fields of the referenced record prefixed by the
name of the table that is referenced.

##### List Functions

List functions are a type of read function that return a set of the requested
type. List functions are mainly used for searching, but can also return the
most recently added records.