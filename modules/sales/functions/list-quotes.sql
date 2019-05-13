CREATE OR REPLACE FUNCTION sales.list_quotes (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      q.order_uuid,
      q.quote_uuid,
      q.status,
      q.issued_at,
      cst.name AS customer_name,
      cst.party_uuid AS customer_uuid,
      contact.name AS contact_name,
      contact.party_uuid AS contact_uuid,
      q.created,
      CASE
        WHEN q.created < o.modified THEN TRUE
        ELSE NULL
      END AS outdated
    FROM json_to_record($1) AS j (
      order_uuid uuid
    )
    INNER JOIN sales.order o
      USING (order_uuid)
    INNER JOIN sales.quote q
      ON q.order_uuid = o.order_uuid
    LEFT JOIN core.party_v cst
      ON cst.party_uuid = o.customer_uuid
    LEFT JOIN core.party_v contact -- Left join as a document may not have a contact
      ON contact.party_uuid = q.contact_uuid
    ORDER BY q.created DESC
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
