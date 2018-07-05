CREATE TABLE address (
  address_id serial PRIMARY KEY,
  addr1 text,
  addr2 text,
  town text,
  state text,
  code text,
  country text,
  type integer, -- 0: residential, 1: business
  created timestamp(0) DEFAULT LOCALTIMESTAMP
)
