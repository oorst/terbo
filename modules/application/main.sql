CREATE SCHEMA app
  CREATE TABLE user (
    user_id   serial PRIMARY KEY,
    person_id integer REFERENCES person (person_id),
    hash      text,
    created   timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE role (
    role_id serial PRIMARY KEY,
    name    text
  )

  CREATE TABLE app_user_role (
    app_user_role_id serial PRIMARY KEY,
    user_id integer REFERENCES app.user (user_id) ON DELETE CASCADE,
    role_id integer REFERENCES role (role_id) ON DELETE CASCADE,
    status  integer DEFAULT 1, -- bit mask
    created timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE VIEW user_v AS
    SELECT u.user_id,
      u.person_id,
      u.hash,
      array(
        SELECT role.name
        FROM app_user_role aur
        INNER JOIN role USING (role_id)
        WHERE aur.user_id = u.user_id AND aur.status & 1 = 1
      ) AS roles
    FROM app.user u;
