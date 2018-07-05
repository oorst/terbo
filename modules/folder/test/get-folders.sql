SELECT f.parent AS "parentId", f.data, node_id AS id
FROM folder.node f
WHERE f.project_id = 22 AND f.access != -1;
