CREATE OR REPLACE FUNCTION sales.create_invoice (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j.user_id AS created_by,
      j.order_id
    FROM json_to_record($1) AS j (
      user_id  integer,
      order_id integer
    )
  ), invoice AS (
    INSERT INTO sales.invoice (
      order_id,
      recipient_id,
      data,
      created_by
    )
    SELECT
      p.order_id,
      o.buyer_id,
      (
        SELECT
          jsonb_build_object(
            'line_items', json_strip_nulls(li)
          )
        FROM sales.line_items(p.order_id) li
      ),
      p.created_by
    FROM payload p
    LEFT JOIN sales.order o
      USING (order_id)
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      i.invoice_id,
      i.order_id,
      i.status,
      i.created,
      p.party_id AS creator_id,
      p.name AS creator_name
    FROM invoice i
    INNER JOIN person p
      ON p.party_id = i.created_by
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
