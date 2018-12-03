CREATE OR REPLACE FUNCTION iam.user (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      p.party_id AS "partyId",
      p.name,
      i.identity_uuid AS "uuid",
      i.hash,
      (
        SELECT
          array_agg(r.name)
        FROM iam.identity_role ir
        LEFT JOIN iam.role r
          USING (role_id)
        WHERE ir.identity_uuid = i.identity_uuid
      ) AS roles
    FROM person p
    INNER JOIN iam.identity i
      USING (party_id)
    WHERE p.email = $1->>'email'
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
