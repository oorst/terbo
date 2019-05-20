CREATE OR REPLACE FUNCTION iam.user (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      p.party_uuid,
      p.name,
      prsn.email,
      i.identity_uuid AS uuid,
      i.hash,
      (
        SELECT
          array_agg(r.name)
        FROM iam.identity_role ir
        LEFT JOIN iam.role r
          USING (role_id)
        WHERE ir.identity_uuid = i.identity_uuid
      ) AS roles
    FROM core.party p
    INNER JOIN core.person prsn
      USING (party_uuid)
    INNER JOIN iam.identity i
      ON i.identity_uuid = p.party_uuid
    WHERE prsn.email = $1->>'email'
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
