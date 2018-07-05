CREATE TABLE address_full (
  address_id    serial PRIMARY KEY,
  lot_number    text,
  road_number_1 text,
  road_number_2 text,
  road_name     text,
  road_type     text,
  road_suffix   text,
  locality_name text,
  state         text,
  code          text
)
