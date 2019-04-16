CREATE OR REPLACE FUNCTION sales.order (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      o.order_id,
      o.buyer_id,
      o.status,
      o.data,
      o.notes,
      o.purchase_order_num,
      o.short_desc,
      o.created,
      t.total_gross,
      t.total_price,
      t.total_tax_amount,
      p.name AS buyer_name
    FROM sales.order o
    LEFT JOIN sales.order_totals(o.order_id) t
      ON t.order_id = o.order_id
    LEFT JOIN party_v p
      ON p.party_id = o.buyer_id
    WHERE o.order_id = ($1->>'order_id')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql';
