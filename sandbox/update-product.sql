SELECT
  i.name
FROM scm.sub_assembly s
inner join scm.item i
  Using(item_uuid)
inner join scm.item p
  on p.item_uuid = s.parent_uuid
inner join prd.product pr
  on pr.product_id = p.product_id;
WHERE pr.family_id = 8;
