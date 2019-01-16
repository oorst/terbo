CREATE OR REPLACE FUNCTION sales.document_totals (jsonb) RETURNS TABLE (
  total_gross      numeric(10,2),
  total_price      numeric(10,2),
  total_tax_amount numeric(10,2)
) AS
$$
BEGIN
  RETURN QUERY
  WITH summed AS (
    SELECT
      sum(r.total_gross) AS total_gross,
      sum(r.total_price) AS total_price
    FROM jsonb_to_recordset($1->'line_items') AS r (
      total_gross numeric(10,2),
      total_price numeric(10,2)
    )
  )
  SELECT
    CASE
      WHEN $1->>'recipient_type' = 'PERSON' AND s.total_price < 1000 THEN
        (s.total_price - t.total_tax_amount)::numeric(10,2)
      ELSE s.total_gross
    END AS total_gross,
    CASE
      WHEN $1->>'recipient_type' = 'PERSON' AND s.total_price < 1000 THEN
        s.total_price
      ELSE (s.total_gross + t.total_tax_amount)::numeric(10,2)
    END AS total_price,
    t.total_tax_amount
  FROM summed s
  LEFT JOIN LATERAL (
    SELECT
      CASE
        WHEN $1->>'recipient_type' = 'PERSON' AND s.total_price < 1000 THEN
          (s.total_price * 0.090909)::numeric(10,2)
        ELSE (s.total_gross * 0.1)::numeric(10,2)
      END AS total_tax_amount
  ) t ON TRUE;
END
$$
LANGUAGE 'plpgsql';
