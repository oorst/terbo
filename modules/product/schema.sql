-- Enables creation of uuids
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA prd;

--
-- Types
--

CREATE TYPE prd.product_t AS ENUM ('PRODUCT', 'SERVICE', 'FAMILY', 'CATEGORY');
CREATE TYPE prd.rounding_rule_t AS ENUM ('NONE', 'NEAREST_INTEGER', 'ROUND_UP');

CREATE TABLE prd.uom (
  uom_id     serial PRIMARY KEY,
  name       text,
  abbr       text,
  type       text
);

CREATE TABLE prd.product (
  product_uuid      uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  family_uuid       uuid REFERENCES prd.product (product_uuid) ON DELETE SET NULL,
  type              prd.product_t DEFAULT 'PRODUCT',
  name              text,
  short_desc        text,
  description       text,
  url               text,
  code              text,
  sku               text UNIQUE,
  manufacturer_uuid uuid REFERENCES core.party (party_uuid) ON DELETE SET NULL,
  manufacturer_code text,
  supplier_uuid     uuid REFERENCES core.party (party_uuid) ON DELETE SET NULL,
  supplier_code     text,
  weight            numeric(10,3),
  -- Text search vector
  tsv               tsvector,
  uom_id            integer REFERENCES prd.uom (uom_id) ON DELETE SET NULL,
  data              jsonb,
  created           timestamptz DEFAULT CURRENT_TIMESTAMP,
  end_at            timestamptz,
  modified          timestamptz DEFAULT CURRENT_TIMESTAMP,
  -- A product must have it's own name or get one from it's family
  CONSTRAINT valid_name CHECK(family_uuid IS NOT NULL OR name IS NOT NULL)
);
  
CREATE TABLE prd.cost (
  cost_uuid    uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  product_uuid uuid REFERENCES prd.product (product_uuid) ON DELETE CASCADE,
  amount       numeric(10,2),
  created      timestamptz DEFAULT CURRENT_TIMESTAMP,
  end_at       timestamptz
);

CREATE TABLE prd.product_attribute (
  attribute_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  product_uuid   uuid REFERENCES prd.product (product_uuid) ON DELETE CASCADE,
  name           text,
  value          text,
  created        timestamp DEFAULT CURRENT_TIMESTAMP,
  created_by     uuid REFERENCES core.party (party_uuid) ON DELETE SET NULL,
  modified       timestamp,
  UNIQUE (product_uuid, name)
);

CREATE TABLE prd.gtin (
  product_uuid uuid REFERENCES prd.product (product_uuid) ON DELETE CASCADE,
  value      text
);

/**
 * Components are for defining composite products.
 */
CREATE TABLE prd.component (
  component_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  parent_uuid    uuid REFERENCES prd.product (product_uuid) ON DELETE CASCADE,
  product_uuid   uuid REFERENCES prd.product (product_uuid) ON DELETE CASCADE,
  quantity       numeric(10,3) DEFAULT 1
); 

CREATE TABLE prd.part (
  part_uuid  uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  parent_uuid  uuid REFERENCES prd.product (product_uuid) ON DELETE CASCADE,
  product_uuid uuid REFERENCES prd.product (product_uuid) ON DELETE CASCADE,
  quantity   numeric(10,3) DEFAULT 1.000,
  part_name  text
);

  --
  -- Associative Tables
  --

CREATE TABLE product_tag (
  product_uuid uuid REFERENCES prd.product (product_uuid) ON DELETE CASCADE,
  tag_uuid     uuid REFERENCES core.tag (tag_uuid) ON DELETE CASCADE
);
      
CREATE OR REPLACE VIEW prd.product_v AS
  SELECT
    p.*,
    u.name AS uom_name,
    u.abbr AS uom_abbr,
    u.type AS uom_type,
    fam.product_uuid AS family_product_uuid,
    fam.name AS family_name,
    fam.code AS family_code,
    EXISTS(
      SELECT
      FROM prd.component component
      WHERE component.parent_uuid = p.product_uuid
    ) AS is_composite,
    -- Is this an assembly product?
    EXISTS(
      SELECT
      FROM prd.part part
      WHERE part.product_uuid = p.product_uuid AND part.parent_uuid IS NULL
    ) AS is_assembly
  FROM prd.product p
  LEFT JOIN prd.uom u
    USING (uom_id)
  LEFT JOIN prd.product fam
    ON p.family_uuid = fam.product_uuid;

CREATE OR REPLACE VIEW prd.product_list_v AS
  SELECT
    p.product_uuid,
    p.type,
    COALESCE(p.sku, p.code, p.supplier_code, p.manufacturer_code, fam.code) AS code,
    COALESCE(p.name, fam.name) AS name,
    COALESCE(p.short_desc, fam.short_desc) AS short_desc,
    p.created,
    p.modified
  FROM prd.product p
  LEFT JOIN prd.product fam
    ON fam.product_uuid = p.family_uuid;
    
CREATE OR REPLACE VIEW prd.component_v AS
  SELECT
    c.component_uuid,
    c.parent_uuid,
    c.product_uuid,
    c.quantity,
    p.name AS product_name,
    uom.name AS uom_name,
    uom.abbr AS uom_abbr
  FROM prd.component c
  LEFT JOIN prd.product p
    USING (product_uuid)
  LEFT JOIN prd.uom uom
    ON uom.uom_id = p.uom_id;

--
-- Triggers
--

-- Update modified column automatically and update parents
CREATE OR REPLACE FUNCTION product_update_tg () RETURNS TRIGGER AS
$$
BEGIN
  NEW.modified = CURRENT_TIMESTAMP;

  -- Update parent products
  UPDATE prd.product p SET (
    modified
  ) = (
    CURRENT_TIMESTAMP
  )
  FROM prd.component c
  WHERE p.product_uuid = c.parent_uuid AND c.product_uuid = NEW.product_uuid;

  RETURN NEW;
END
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER product_update_tg BEFORE UPDATE ON prd.product
  FOR EACH ROW EXECUTE PROCEDURE product_update_tg();

-- Update parents on component update
CREATE OR REPLACE FUNCTION component_update_tg () RETURNS TRIGGER AS
$$
BEGIN
  -- Update parent products
  UPDATE prd.product p SET (
    modified
  ) = (
    CURRENT_TIMESTAMP
  )
  FROM prd.component c
  WHERE p.product_uuid = c.product_uuid AND c.component_uuid = NEW.component_uuid;

  RETURN NEW;
END
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER product_update_tg BEFORE UPDATE ON prd.component
  FOR EACH ROW EXECUTE PROCEDURE component_update_tg();

CREATE FUNCTION product_weighted_tsv_trigger() RETURNS trigger AS
$$
BEGIN
  new.tsv :=
     setweight(to_tsvector('simple', COALESCE(new.name,'')), 'A') ||
     setweight(to_tsvector('simple', COALESCE(new.code,'')), 'A') ||
     setweight(to_tsvector('simple', COALESCE(new.sku,'')), 'A') ||
     setweight(to_tsvector('english', COALESCE(new.short_desc,'')), 'B');

  RETURN new;
END
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER upd_product_tsvector BEFORE INSERT OR UPDATE ON prd.product
FOR EACH ROW EXECUTE PROCEDURE product_weighted_tsv_trigger();
