### API

The Terbo API is implemented through functions.  API functions take and return
json type.

API functions are granted the permissions of the definer.  Private functions are
not.

#### Fields

When updating, only fields that are present on the payload will be updated.
Omitted fields will remain as they were before the update. To explicitly set a
filed to NULL, set the corresponding payload property to `null`.

#### Naming conventions

##### API Functions

- create_<type> something will insert something into the database.
- get_<type> retrieves a single record of some sort.
- find_<type> retrieves multiple records of some sort
- json_to_<type> prefix is a query of some sort.  Send in some json and get some json
back.
- search looks for things of different criteria.

##### Private functions

insert_ inserts something and returns a record of the insertion
