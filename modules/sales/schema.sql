CREATE TYPE document_status_t AS ENUM ('DRAFT', 'ISSUED', 'DELETED', 'VOID');
CREATE TYPE invoice_status_t AS ENUM ('draft', 'issued', 'deleted', 'void');
CREATE TYPE order_status_t AS ENUM ('RECEIVED', 'PENDING', 'FULFILLED', 'DELIVERED');
CREATE TYPE pmt_status_t AS ENUM ('owing', 'paid');
CREATE TYPE li_note_importance_t AS ENUM ('normal', 'important');

CREATE SCHEMA sales
  -- CREATE TABLE source_document (
  --   document_id  serial PRIMARY KEY,
  --   issued_to    integer NOT NULL REFERENCES party (party_id) ON DELETE SET NULL,
  --   contact_id   integer NOT NULL REFERENCES person (party_id) ON DELETE SET NULL,
  --   data         jsonb,
  --   status       document_status_t DEFAULT 'DRAFT',
  --   created_by   integer NOT NULL REFERENCES person (party_id) ON DELETE SET NULL,
  --   created      timestamp DEFAULT CURRENT_TIMESTAMP,
  --   modified     timestamp
  -- )

  CREATE TABLE order (
    order_id            serial PRIMARY KEY,
    buyer_id            integer REFERENCES party (party_id) ON DELETE SET NULL,
    delivery_address_id integer REFERENCES address (address_id) ON DELETE SET NULL,
    status              order_status_t DEFAULT 'PENDING',
    notes               text,
    created             timestamp DEFAULT CURRENT_TIMESTAMP,
    created_by          integer REFERENCES person (party_id) NOT NULL
  )

  CREATE TABLE invoice (
    invoice_id     serial PRIMARY KEY,
    invoice_num    text,
    document_id    integer REFERENCES source_document (document_id) ON DELETE RESTRICT,
    order_id       integer REFERENCES sales.order (order_id) ON DELETE RESTRICT,
    contact_id     integer REFERENCES person (party_id) ON DELETE SET NULL,
    -- Local time
    period         integer NOT NULL DEFAULT 30,
    due_date       timestamp,
    payment_status pmt_status_t DEFAULT 'owing',
    notes          text,
    issued_at      timestamp,
    created        timestamp DEFAULT CURRENT_TIMESTAMP,
    created_by     integer REFERENCES person (party_id) NOT NULL,
    modified       timestamp
  )

  CREATE TABLE invoice_memo (
    memo_id    serial PRIMARY KEY,
    invoice_id integer REFERENCES invoice (invoice_id) ON DELETE CASCADE,
    body       text,
    created    timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE quote (
    quote_id    serial PRIMARY KEY,
    order_id    integer REFERENCES sales.order (order_id) ON DELETE CASCADE,
    period      integer NOT NULL DEFAULT 30,
    expiry_date date,
    contact_id  integer REFERENCES person (party_id),
    notes       text,
    status      document_status_t DEFAULT 'DRAFT',
    issued_at   timestamp,
    created     timestamp DEFAULT CURRENT_TIMESTAMP,
    created_by  integer REFERENCES person (party_id),
    modified    timestamp
  )

  CREATE TABLE payment (
    payment_id serial PRIMARY KEY,
    invoice_id integer REFERENCES invoice (invoice_id),
    amount     numeric(10,2),
    created    timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE purchase_order (
    document_id integer REFERENCES source_document (document_id) ON DELETE CASCADE,
    approved_by integer REFERENCES person (party_id) ON DELETE SET NULL,
    notes       text,
    issued_at   timestamp,
    created     timestamp DEFAULT CURRENT_TIMESTAMP,
    modified    timestamp,
    PRIMARY KEY (document_id)
  )

  CREATE TABLE line_item (
    line_item_id        serial PRIMARY KEY,
    order_id            integer REFERENCES source_document (document_id) ON DELETE CASCADE,
    product_id          integer REFERENCES prd.product (product_id) ON DELETE RESTRICT,
    -- The order in which the line items appear in a document
    position            smallint,
    code                text,
    name                text,
    description         text,
    -- Misc data to be stored with line item
    data                jsonb,
    -- Percentage discount
    discount_pc         numeric(3,2),
    -- Dollar amount discount
    discount_amt        numeric(10,2),
    -- Named discount if applied
    discount_name       text,
    -- Gross price charged
    gross               numeric(10,2),
    -- Net price charged, no extra tax is applied
    net                 numeric(10,2),
    uom_id              integer REFERENCES prd.uom (uom_id) ON DELETE SET NULL,
    quantity            numeric(10,3),
    tax                 boolean DEFAULT TRUE,
    delivery_address_id integer REFERENCES address (address_id),
    note                text,
    note_importance     li_note_importance_t DEFAULT 'normal',
    created             timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE order_line_item (
    order_id integer REFERENCES sales.order (order_id) ON DELETE RESTRICT,
    line_item_id integer REFERENCES line_item (line_item_id) ON DELETE CASCADE,
    PRIMARY KEY (line_item_id)
  )

  CREATE VIEW invoice_v AS
    SELECT
      i.*,
      d.issued_to,
      d.contact_id,
      d.data,
      d.status,
      d.created_by
    FROM invoice i
    INNER JOIN source_document d
      USING (document_id)

  CREATE VIEW quote_v AS
    SELECT
      q.*,
      o.buyer_id,
      q.contact_id,
      q.data,
      q.status,
      d.created_by
    FROM quote q
    INNER JOIN sales.order o
      USING (order_id);

--
-- Rules
--

CREATE OR REPLACE RULE sales_invoice_v_update AS ON UPDATE TO sales.invoice_v
  DO INSTEAD (
    -- Update source first, trigger should throw exception here if update not allowed
    UPDATE sales.source_document d
    SET
      contact_id = NEW.contact_id,
      status = NEW.status,
      data = NEW.data
    WHERE d.document_id = NEW.document_id;

    UPDATE sales.invoice i
    SET
      issued_at = NEW.issued_at,
      period = NEW.period,
      due_date = NEW.due_date,
      notes = NEW.notes
    WHERE i.document_id = NEW.document_id;
  );

CREATE RULE sales_quote_v_update AS ON UPDATE TO sales.quote_v
  DO INSTEAD (
    -- Update source first, trigger should throw exception here if update not allowed
    UPDATE sales.source_document d
    SET
      contact_id = NEW.contact_id,
      status = NEW.status,
      data = NEW.data
    WHERE d.document_id = NEW.document_id;

    UPDATE sales.quote q
    SET
      issued_at = NEW.issued_at,
      period = NEW.period,
      expiry_date = NEW.expiry_date,
      notes = NEW.notes
    WHERE q.document_id = NEW.document_id;
  );

--
-- Triggers
--
CREATE OR REPLACE FUNCTION sales.source_document_upd_tg() RETURNS trigger AS
$$
BEGIN
  IF OLD.status != 'DRAFT' THEN
    RAISE EXCEPTION 'not allowed to update % %', lower(OLD.status::text), lower(TG_TABLE_NAME)
      USING HINT = 'only drafts can be updated', ERRCODE = 'U0004';
  END IF;

  SELECT CURRENT_TIMESTAMP INTO NEW.modified;

  RETURN NEW;
END
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER sales_source_document_upd_tg BEFORE UPDATE ON sales.source_document
  FOR EACH ROW EXECUTE PROCEDURE sales.source_document_upd_tg();

CREATE TRIGGER sales_invoice_upd_tg BEFORE UPDATE ON sales.invoice
  FOR EACH ROW EXECUTE PROCEDURE update_modified_tg();

CREATE TRIGGER sales_quote_upd_tg BEFORE UPDATE ON sales.quote
  FOR EACH ROW EXECUTE PROCEDURE update_modified_tg();
