CREATE VIEW hucx.user_v AS
  SELECT
    p.name AS name,
    p.email AS email,
    u.user_id AS user_id,
    p.person_id AS person_id,
    u.hash AS hash,
    u.roles AS roles
  FROM person p
  INNER JOIN application.user_v u
    USING (person_id);
