/*
Ejercicio 1: 
	9. Listar el Número, nombre, apellido, estado, cantidad de Órdenes, monto total comprado por Cliente durante el año 2015 que 
	no sean del estado de Florida.
	Mostrar sólo aquellos clientes cuyo monto total comprado sea mayor que el promedio del monto total comprado por 
	Cliente que no sean del estado Florida. Ordenado por total comprado en forma descendente.
*/
SELECT 
	c.customer_num, 
	c.fname, 
	c.lname, 
	c.state, 
	COUNT(o.order_num) AS cant_ordenes, 
	SUM(i.quantity * i.unit_price) AS monto_total
FROM 
	customer c
	JOIN orders o ON c.customer_num = o.customer_num
	JOIN items i ON o.order_num = i.order_num
WHERE 
	YEAR(o.order_date) = 2015 AND 
	c.state != 'FL'
GROUP BY 
	c.customer_num, 
	c.fname, 
	c.lname, 
	c.state
HAVING 
	SUM(i.quantity * i.unit_price) > (
		SELECT 
			AVG(total_por_cliente) 
		FROM (
			SELECT 
				SUM(i2.quantity * i2.unit_price) AS total_por_cliente
			FROM 
				customer c2 
				JOIN orders o2 ON c2.customer_num = o2.customer_num
				JOIN items i2 ON o2.order_num = i2.order_num
			WHERE 
				YEAR(o2.order_date) = 2015 AND
				c2.state != 'FL'
			GROUP BY 
				c2.customer_num
		) AS sub_consulta
	)
ORDER BY 
	monto_total DESC; 

/*
Ejercicio 2: 
	10. Seleccionar todos los clientes cuyo monto total comprado sea mayor al de su referente durante el año 2015. 
	Mostrar número, nombre, apellido y los montos totales comprados de ambos durante ese año. 
	Tener en cuenta que un cliente puede no tener referente y que el referente pudo no haber 
	comprado nada durante el año 2015, mostrarlo igual.
*/
SELECT 
	c.customer_num, 
	c.fname, 
	c.lname, 
	SUM(i.quantity * i.unit_price) AS monto_total, 
	ref_totals.monto_referente
FROM 
	customer c
	LEFT JOIN orders o ON c.customer_num = o.customer_num 
    LEFT JOIN items i ON o.order_num = i.order_num
	LEFT JOIN (
		SELECT 
			c2.customer_num AS refered_id, 
			SUM(i2.quantity * i2.unit_price) AS monto_referente
		FROM 
			customer c2
			LEFT JOIN orders o2 ON c2.customer_num = o2.customer_num
			LEFT JOIN items i2 ON o2.order_num = i2.order_num
		GROUP BY 
			c2.customer_num
	) AS ref_totals ON c.customer_num_referedBy = ref_totals.refered_id
WHERE 
	YEAR(o.order_date) = 2015 
GROUP BY 
	c.customer_num, 
	c.fname, 
	c.lname, 
	ref_totals.monto_referente
HAVING 
	SUM(i.quantity * i.unit_price) > ref_totals.monto_referente;