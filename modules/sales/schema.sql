CREATE TYPE document_status_t AS ENUM ('DRAFT', 'ISSUED', 'DELETED', 'VOID');
CREATE TYPE invoice_status_t AS ENUM ('draft', 'issued', 'deleted', 'void');
CREATE TYPE pmt_status_t AS ENUM ('owing', 'paid');
CREATE TYPE li_note_importance_t AS ENUM ('normal', 'important');

CREATE SCHEMA sales
  CREATE TABLE source_document (
    document_id  serial PRIMARY KEY,
    issued_to    integer REFERENCES party (party_id) NOT NULL ON DELETE SET NULL,
    issued_by    integer REFERENCES party (party_id) NOT NULL ON DELETE SET NULL,
    data         jsonb,
    status       document_status_t DEFAULT 'DRAFT',
    issued_at    timestamp,
    created      timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE invoice (
    invoice_id     serial PRIMARY KEY,
    invoice_num    text,
    document_id    integer REFERENCES source_document (document_id) ON DELETE RESTRICT,
    -- Invoices are issued to a Party
    issued_to      integer,
    -- Local time
    due_date       timestamp,
    status         invoice_status_t DEFAULT 'draft',
    payment_status pmt_status_t DEFAULT 'owing',
    issued_at      timestamp DEFAULT CURRENT_TIMESTAMP,
    created        timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE invoice_memo (
    memo_id    serial PRIMARY KEY,
    invoice_id integer REFERENCES invoice (invoice_id) ON DELETE CASCADE,
    body       text,
    created    timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE quote (
    document_id integer REFERENCES sales.source_document (document_id),
    quote_num   text,
    period      integer NOT NULL DEFAULT 30,
    expiry_date date,
    PRIMARY KEY (quote_id)
  )

  CREATE TABLE payment (
    payment_id serial PRIMARY KEY,
    invoice_id integer REFERENCES invoice (invoice_id),
    amount     numeric(10,2),
    created    timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE line_item (
    document_id     integer REFERENCES source_document (document_id) ON DELETE CASCADE,
    code            text,
    name            text,
    description     text,
    -- Misc data to be stored with line item
    data            jsonb,
    -- Percentage discount
    discount_pc     numeric(3,2),
    -- Dollar amount discount
    discount_amt    numeric(10,2),
    -- Named discount if applied
    discount_name   text,
    -- Gross price charged
    gross           numeric(10,2),
    -- Net price charged, no extra tax is applied
    net             numeric(10,2),
    uom_id          integer REFERENCES prd.uom (uom_id) ON DELETE SET NULL,
    quantity        numeric(10,3),
    tax             boolean DEFAULT TRUE,
    note            text,
    note_importance li_note_importance_t DEFAULT 'normal',
    created         timestamp DEFAULT CURRENT_TIMESTAMP
  );

--
-- Triggers
--
CREATE FUNCTION sales.document_tg() RETURNS trigger AS
$$
BEGIN
  IF OLD.status != 'DRAFT' THEN
    RAISE EXCEPTION 'not allowed to update % %', lower(OLD.status), lower(TG_TABLE_NAME)
      USING HINT = 'only drafts can be updated', ERRCODE = 'U0004';
  END IF;

  -- Return the new row
  RETURN NEW;
END
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER sales_document_tg BEFORE UPDATE ON sales.source_document
    FOR EACH ROW EXECUTE PROCEDURE sales.document_tg();

CREATE TRIGGER sales_invoice_tg BEFORE UPDATE ON sales.invoice
    FOR EACH ROW EXECUTE PROCEDURE sales.document_tg();

CREATE TRIGGER sales_quote_tg BEFORE UPDATE ON sales.quote
    FOR EACH ROW EXECUTE PROCEDURE sales.document_tg();
