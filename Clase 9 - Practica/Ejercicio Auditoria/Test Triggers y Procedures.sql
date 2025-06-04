/*MUESTRO TABLA AUDITORIA*/
SELECT 
	*
FROM 
	auditoria 

/*PRUEBO TRIGGER DE INSERT*/
INSERT INTO manufact (manu_code, manu_name, lead_time, state)
VALUES ('A01', 'Sony', 10, 'NY');

/*PRUEBO TRIGGER DE DELETE*/
INSERT INTO manufact (manu_code, manu_name, lead_time, state)
VALUES ('B02', 'LG', 15, 'CA');

DELETE FROM manufact
WHERE manu_code = 'B02';

/*PRUEBO TRIGGER DE UPDATE*/
INSERT INTO manufact (manu_code, manu_name, lead_time, state)
VALUES ('Z01', 'Sony', 15, 'CA');

UPDATE manufact
SET manu_name = 'Sony Corp', lead_time = 20, state = 'NV'
WHERE manu_code = 'Z01';


