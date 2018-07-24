CREATE FUNCTION update_modified_tg () RETURNS trigger AS
$$
BEGIN
  SELECT CURRENT_TIMESTAMP INTO NEW.modified;

  RETURN NEW;
END
$$
LANGUAGE 'plpgsql';
