CREATE OR REPLACE FUNCTION sales.order_totals (
  integer,
  buyer_type party_t DEFAULT NULL
) RETURNS TABLE (
  order_id         integer,
  total_gross      numeric(10,2),
  total_price      numeric(10,2),
  total_tax_amount numeric(10,2)
) AS
$$
BEGIN
  RETURN QUERY
  WITH summed AS (
    SELECT
      sum(li.total_gross) AS total_gross,
      sum(li.total_price) AS total_price
    FROM sales.line_item_v li
    WHERE li.order_id = $1
  )
  SELECT
    $1 AS order_id,
    CASE
      WHEN buyer_type = 'PERSON' AND s.total_price < 1000 THEN
        (s.total_price - t.total_tax_amount)::numeric(10,2)
      ELSE s.total_gross
    END AS total_gross,
    CASE
      WHEN buyer_type = 'PERSON' AND s.total_price < 1000 THEN
        s.total_price
      ELSE (s.total_gross + t.total_tax_amount)::numeric(10,2)
    END AS total_price,
    t.total_tax_amount
  FROM summed s
  LEFT JOIN LATERAL (
    SELECT
      CASE
        WHEN buyer_type = 'PERSON' AND s.total_price < 1000 THEN
          (s.total_price * 0.090909)::numeric(10,2)
        ELSE (s.total_gross * 0.1)::numeric(10,2)
      END AS total_tax_amount
  ) t ON TRUE;
END
$$
LANGUAGE 'plpgsql';
