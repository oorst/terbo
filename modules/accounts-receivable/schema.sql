CREATE SCHEMA ar;

CREATE TYPE ar.issuance_status_t AS ENUM (
  'AWAITING_ISSUE',
  'PROFORMA',
  'ISSUED',
  'VOID'
);

CREATE TYPE ar.payment_status_t AS ENUM (
  'OWING',
  'PAID'
);

CREATE TYPE ar.payment_time_t AS ENUM (
  'ON_TIME',
  'LATE'
);

CREATE TABLE ar.invoice (
  invoice_uuid    uuid REFERENCES core.document PRIMARY KEY,
  payor_uuid      uuid REFERENCES core.party (party_uuid) NOT NULL,
  contact_uuid    uuid REFERENCES core.party (party_uuid),
  due_date        timestamptz,
  issuance_status ar.issuance_status_t NOT NULL DEFAULT 'AWAITING_ISSUE',
  payment_status  ar.payment_status_t
);

CREATE TABLE ar.receipt (
  receipt_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  invoice_uuid uuid REFERENCES ar.invoice (invoice_uuid) NOT NULL,
  payment_time ar.payment_time_t
);

CREATE TABLE ar.invoice_detail (
  detail_uuid    uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  invoice_uuid   uuid REFERENCES ar.invoice (invoice_uuid) ON DELETE CASCADE,
  line_position  smallint,
  name           text,
  short_desc     text,
  amount_payable numeric(10,2)
);

CREATE TABLE ar.line_item (
  line_item_uuid  uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  invoice_uuid    uuid,
  product_uuid    uuid,
  line_position   smallint,
  name            text,
  short_desc      text,
  discount        numeric(5,2),  -- Computed price of the line
  total_gross     numeric(10,2),
  total_price     numeric(10,2),
  tax_excluded    boolean,
  delivery_id     integer,
  created         timestamptz,
  modified        timestamptz
);

--
-- Views
--

CREATE OR REPLACE VIEW ar.invoice_v AS
  SELECT
    i.*,
    d.document_num,
    d.approval_status,
    d.data,
    d.created,
    payor.name AS payor_name,
    contact.name AS contact_name,
    (
      SELECT
        sum(id.amount_payable)::numeric(10,2)
      FROM ar.invoice_detail id
      WHERE id.invoice_uuid = i.invoice_uuid
    ) AS amount_payable
  FROM ar.invoice i
  INNER JOIN core.document d
    ON d.document_uuid = i.invoice_uuid
  LEFT JOIN core.party payor
    ON payor.party_uuid = i.payor_uuid
  LEFT JOIN core.party contact
    ON contact.party_uuid = i.contact_uuid;

--
-- Triggers
--

CREATE OR REPLACE FUNCTION ar.insert_invoice_tg () RETURNS TRIGGER AS
$$
BEGIN
  INSERT INTO core.document (
    kind,
    origin,
    approval_status
  ) VALUES (
    'invoice',
    'accounts_receivable',
    'DRAFT'
  )
  RETURNING document_uuid INTO NEW.invoice_uuid;

  RETURN NEW;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

CREATE TRIGGER ar_invoice_document_tg BEFORE INSERT ON ar.invoice
FOR EACH ROW EXECUTE PROCEDURE ar.insert_invoice_tg();
