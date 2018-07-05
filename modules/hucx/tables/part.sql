/**
A Part is a thing that is made from one or more instances of a Product.
The composition of a Part is essentially a list of SKUs and quantities.
Parts should be kept to as few physical SKUs as possible, but many instangible
SKUs like electricty or overheads may be necessary to provide accurate data.
*/

CREATE TABLE hucx.part (
  part_id  serial PRIMARY KEY,
  block_id integer REFERENCES hucx.block(block_id) ON DELETE CASCADE,
  data     jsonb,
  created  timestamp(0) DEFAULT CURRENT_TIMESTAMP,
  modified timestamp(0) DEFAULT CURRENT_TIMESTAMP
)
