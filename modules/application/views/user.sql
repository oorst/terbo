CREATE VIEW application.user_v AS
  SELECT u.user_id,
    u.person_id,
    u.hash,
    array(
      SELECT role.name
      FROM application.app_user_role aur
      INNER JOIN application.role role USING (role_id)
      WHERE aur.user_id = u.user_id AND aur.status & 1 = 1
    ) AS roles
  FROM application.user u;
