/*
# scm.insert_item_instance (uuid, deep)

* `uuid` {uuid} UUID of the prototype *Item*
* `deep` {boolean} Clone the complete prototype hierarchy

Create an instance of an existing *Item*.  Clones the *Item* given in `uuid`.
Creates a deep clone if `deep` is set to true.
*/
CREATE OR REPLACE FUNCTION scm.insert_item_instance (uuid, deep DEFAULT FALSE, OUT result uuid) AS
$$
BEGIN
  WITH RECURSIVE root AS (
    INSERT INTO scm.item_instance (
      item_uuid
    ) VALUES (
      $1
    )
    RETURNING *
  ), hierarchy AS (
    
  )
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
