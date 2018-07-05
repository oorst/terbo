CREATE VIEW party_v AS
  SELECT
    name,
    person_id,
    NULL AS organisation_id,
    party_id
  FROM person

  UNION

  SELECT
    name,
    NULL AS person_id,
    organisation_id,
    party_id
  FROM organisation;
