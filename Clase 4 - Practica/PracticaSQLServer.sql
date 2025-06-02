/*Ejercicio 2: Insertar el siguiente cliente en la tabla #clientes
Customer_num 144
Fname Agustín
Lname Creevy
Company Jaguares SA
State CA
City Los Angeles*/

CREATE TABLE #clientes (
    customer_num INT,
    fname VARCHAR(50),
    lname VARCHAR(50),
    company VARCHAR(100),
    state CHAR(2),
    city VARCHAR(50)
);


INSERT 
INTO #clientes 
	(customer_num, fname, lname, company, state, city)
VALUES 
	(144, 'Agustín', 'Creevy', 'Jaguares SA', 'CA', 'Los Angeles');

SELECT 
	*
FROM 
	#clientes


/*Ejercicio 3: Crear una tabla temporal #clientesCalifornia con la misma estructura de la tabla customer.
Realizar un insert masivo en la tabla #clientesCalifornia con todos los clientes de la tabla customer cuyo
state sea CA.*/

SELECT 
	* 
INTO 
	#temp_clientesCalifornia 
FROM 
	customer 
WHERE 
	state = 'CA'

SELECT 
	*
FROM 
	#temp_clientesCalifornia


/*Ejercicio 4: Insertar el siguiente cliente en la tabla #clientes un cliente que tenga los mismos datos del cliente 103,
pero cambiando en customer_num por 155
Valide lo insertado.*/

SELECT 
	customer_num = 155, 
	fname, 
	lname, 
	company, 
	address1, 
	address2, 
	city,
	state, 
	zipcode, 
	phone
INTO 
	#clientes_vol2
FROM 
	customer 
WHERE
	customer_num = 103

SELECT 
	*
FROM 
	#clientes_vol2


/*Ejercicio 5: Modificar los registros de la tabla #clientes cambiando el campo state por ‘AK’ y el campo address2 por
‘Barrio Las Heras’ para los clientes que vivan en el state 'CO'. Validar previamente la cantidad de
registros a modificar.*/

SELECT 
	*
FROM 
	customer
WHERE
	state = 'CO'

SELECT
	customer_num, 
	fname, 
	lname, 
	company, 
	address1, 
	address2 = 'Barrio Las Heras', 
	city,
	state = 'AK', 
	zipcode, 
	phone
INTO 
	#clientes_co
FROM 
	customer 
WHERE
	state = 'CO'

SELECT 
	*
FROM 
	#clientes_co