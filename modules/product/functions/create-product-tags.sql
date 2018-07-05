CREATE OR REPLACE FUNCTION prd.create_product_tags (integer, json) RETURNS void
AS
$$
BEGIN
  INSERT INTO prd.tag (name)
  SELECT value
  FROM json_array_elements_text($2)
  ON CONFLICT DO NOTHING;

  INSERT INTO prd.product_tag (
    product_id,
    tag_id
  )
  SELECT
    $1, tag_id
  FROM prd.tag
  WHERE name IN (
    SELECT value
    FROM json_array_elements_text($2)
  ) AND name NOT IN (
    SELECT unnest(tags)
    FROM prd.product_v pr
    WHERE pr.product_id = $1
  );

  -- Delete tags if they are not in the array
  DELETE FROM prd.product_tag
  WHERE product_id = $1 AND tag_id NOT IN (
    SELECT tag_id
    FROM prd.tag
    WHERE name IN (
      SELECT value
      FROM json_array_elements_text($2)
    )
  );
END
$$
LANGUAGE 'plpgsql';
