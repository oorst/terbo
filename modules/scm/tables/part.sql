CREATE TABLE man.part (
  part_id     serial PRIMARY KEY,
  bom_id      integer REFERENCES man.bom (bom_id),
  bom_line_id integer REFERENCES man.bom_line (bom_line_id),
  data        jsonb,
  route_id    integer REFERENCES man.route (route_id),
  created     timestamp (0) DEFAULT CURRENT_TIMESTAMP
)
