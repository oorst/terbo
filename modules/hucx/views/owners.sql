CREATE VIEW hucx.owners AS
  SELECT o.owner_id, p.person_id, p.organisation_id
  FROM hucx.owner o
  INNER JOIN party p USING (party_id);
