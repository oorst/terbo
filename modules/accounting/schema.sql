CREATE SCHEMA acc;

CREATE TABLE acc.invoice (
  invoice_uuid   uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  invoice_num    text,
  recipient_uuid uuid REFERENCES core.party (party_uuid) ON DELETE RESTRICT,
  contact_uuid   uuid REFERENCES core.person (party_uuid) ON DELETE SET NULL,
  period         integer NOT NULL DEFAULT 30,
  due_date       timestamptz,
  status         sales.document_status_t DEFAULT 'DRAFT',
  payment_status sales.payment_status_t DEFAULT 'OWING',
  short_desc     text,
  notes          text,
  data           jsonb,
  issued_at      timestamptz,
  created        timestamptz DEFAULT CURRENT_TIMESTAMP,
  created_by     uuid REFERENCES core.person (party_uuid) NOT NULL,
  modified       timestamptz
);