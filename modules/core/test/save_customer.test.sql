SELECT *
FROM people p
WHERE p.person_id IN (SELECT save_customer('{"type": "person", "name": "john test", "email": "john@test.com"}'::json));
