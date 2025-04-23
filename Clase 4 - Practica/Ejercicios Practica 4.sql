-- EJERCICIO 1: Crear una tabla temporal #clientes a partir de la siguiente consulta: SELECT * FROM customer
SELECT * 
INTO 
    #clientes
FROM 
    customer; 

-- EJERCICIO 2: INSERTAR CLIENTE 
INSERT INTO #clientes (
    customer_num, 
    fname, 
    lname, 
    company, 
    state, 
    city
)
VALUES (
    144, 
    'Agustín', 
    'Creevy', 
    'Jaguares SA', 
    'CA', 
    'Los Angeles'
)

-- EJERCICIO 3: Crear una tabla temporal #clientesCalifornia con la misma estructura de la tabla customer.
-- Realizar un insert masivo en la tabla #clientesCalifornia con todos los clientes de la tabla customer cuyo
-- state sea CA.

CREATE TABLE #clientesCalifornia (
    [customer_num] [smallint] NOT NULL,
	[fname] [varchar](15) NULL,
	[lname] [varchar](15) NULL,
	[company] [varchar](20) NULL,
	[address1] [varchar](20) NULL,
	[address2] [varchar](20) NULL,
	[city] [varchar](15) NULL,
	[state] [char](2) NULL,
	[zipcode] [char](5) NULL,
	[phone] [varchar](18) NULL,
	[customer_num_referedBy] [smallint] NULL,
	[status] [char](1) NULL,
)

INSERT INTO #clientesCalifornia 
SELECT *
FROM 
    customer 
WHERE 
    state = 'CA'

-- EJERCICIO 4: Insertar el siguiente cliente en la tabla #clientes un cliente que tenga los mismos datos del cliente 103,
-- pero cambiando en customer_num por 155
-- Valide lo insertado.
INSERT INTO #clientes 
SELECT 
    155 AS customer_num,
    fname,
    lname,
    company,
    address1,
    address2,
    city,
    state,
    zipcode,
    phone,
    customer_num_referedBy,
    status
FROM 
    customer
WHERE 
    customer_num = 103;

SELECT *
FROM 
    #clientes
WHERE 
    customer_num = 155;

-- EJERCICIO 5: Borrar de la tabla #clientes los clientes cuyo campo zipcode esté entre 94000 y 94050 y la ciudad
-- comience con ‘M’. Validar los registros a borrar antes de ejecutar la acción.
SELECT
FROM 
    #customer 
WHERE 
    zipcode BETWEEN 94000 AND 94050 AND 
    city LIKE 'M%';

DELETE 
FROM 
    #customer 
WHERE 
    zipcode BETWEEN 94000 AND 94050 AND 
    city LIKE 'M%';


-- EJERCICIO 6: Modificar los registros de la tabla #clientes cambiando el campo state por ‘AK’ y el campo address2 por
-- ‘Barrio Las Heras’ para los clientes que vivan en el state 'CO'. Validar previamente la cantidad de
-- registros a modificar.
SELECT 
    COUNT (*) AS cantidad_registros_a_modificar
FROM 
    #clientes 
WHERE 
    state = 'CO';

UPDATE #clientes 
SET
    state = 'AK',
    address2 = 'Barrio Las Heras'
WHERE 
    state = 'CO'; 


-- EJERCICIO 7: Modificar todos los clientes de la tabla #clientes, agregando un dígito 1 delante de cada número
-- telefónico, debido a un cambio de la compañía de teléfonos.
UPDATE #clientes 
SET 
    phone = '1' + phone; 