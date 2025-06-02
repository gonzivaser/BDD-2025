/*Ejercicio 1: Obtener un listado de todos los clientes y sus direcciones. */
SELECT 
    customer_num,
    address1,
    address2
INTO 
	#temp_clientes_direcciones
FROM 
	customer;

SELECT 
	*
FROM 
	#temp_clientes_direcciones


/*Ejercicio 2: Obtener el listado anterior pero sólo los clientes que viven en el estado de California “CA”.  */
SELECT 
	c.customer_num
INTO 
	#temp_cliente_CA
FROM 
	customer c
WHERE 
	c.state = 'CA'

SELECT 
	*
FROM 
	#temp_cliente_CA


/*Ejercicio 3 y 4: Listar todas las ciudades (city) de la tabla clientes que pertenecen al estado de “CA”, mostrar sólo una vez
cada ciudad y ordenar ALFABETICAMENTE  */
SELECT DISTINCT 
	c.city 
INTO 
	#temp_city_CA
FROM 
	customer c
WHERE 
	c.state = 'CA'
ORDER BY 
	city ASC;

SELECT 
	*
FROM 
	#temp_city_CA
