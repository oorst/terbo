/**
set_owner will set the owner of a project when provided with a _Party_ id.
*/

CREATE OR REPLACE FUNCTION hucx.set_owner (json, OUT result json) AS
$$
BEGIN
  IF $1->>'ownerId' IS NULL OR $1->>'projectId' IS NULL THEN
    RAISE EXCEPTION 'Bad input.  No partyId or projectId';
  END IF;

  UPDATE hucx.project
  SET owner = ($1->>'ownerId')::integer
END
$$
LANGUAGE  ;
