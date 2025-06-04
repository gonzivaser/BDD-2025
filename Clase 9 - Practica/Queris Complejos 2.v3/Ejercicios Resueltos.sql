/*Ejercicio 1: 
	Crear una vista que devuelva:
a) Código y Nombre (manu_code,manu_name) de los fabricante, posean o no productos
(en tabla Products), cantidad de productos que fabrican (cant_producto) y la fecha de
la última OC que contenga un producto suyo (ult_fecha_orden).
 De los fabricantes que fabriquen productos sólo se podrán mostrar los que
fabriquen más de 2 productos.
 No se permite utilizar funciones definidas por usuario, ni tablas temporales, ni
UNION.

b) Realizar una consulta sobre la vista que devuelva manu_code, manu_name,
cant_producto y si el campo ult_fecha_orden posee un NULL informar ‘No Posee
Órdenes’ si no posee NULL informar el valor de dicho campo.
 No se puede utilizar UNION para el SELECT.
*/

/*a) */
CREATE VIEW vista_fabricantes_productos 
AS
SELECT 
	m.manu_code, 
	m.manu_name, 
	COUNT(DISTINCT p.stock_num) AS cant_productos, 
	MAX(o.order_date) AS ult_fecha_orden
FROM 
	manufact m
LEFT JOIN products p
	ON m.manu_code = p.manu_code
LEFT JOIN items i
	ON p.stock_num = i.stock_num AND p.manu_code = i.manu_code
LEFT JOIN orders o 
	ON i.order_num = o.order_num
GROUP BY 
	m.manu_code, 
	m.manu_name
HAVING 
	COUNT(DISTINCT p.stock_num) = 0 OR COUNT(DISTINCT p.stock_num) > 2;

/*MUESTRO TABLA*/
SELECT 
	*
FROM 
	vista_fabricantes_productos

/*b) */
SELECT 
	manu_code, 
	manu_name,
	cant_productos, 
	CASE 
		WHEN ult_fecha_orden IS NULL THEN 'No posee ordenes'
		ELSE CAST(ult_fecha_orden AS VARCHAR)
	END AS ult_fecha_orden 
FROM 
	vista_fabricantes_productos


/*Ejercicio 2: 
	Desarrollar una consulta ABC de fabricantes que:
Liste el código y nombre del fabricante, la cantidad de órdenes de compra que contengan
sus productos y la monto total de los productos vendidos.
Mostrar sólo los fabricantes cuyo código comience con A ó con N y posea 3 letras, y los
productos cuya descripción posean el string “tennis” ó el string “ball” en cualquier parte del
nombre y cuyo monto total vendido sea mayor que el total de ventas promedio de todos
los fabricantes (Cantidad * precio unitario / Cantidad de fabricantes que vendieron sus
productos).
Mostrar los registros ordenados por monto total vendido de mayor a menor.
*/

SELECT 
	m.manu_code, 
	m.manu_name, 
	COUNT(DISTINCT o.order_num) AS cant_ordenes,
	SUM(i.quantity * i.unit_price) AS monto_total_prod_vendidos
FROM 
	manufact m
JOIN products p
	ON m.manu_code = p.manu_code
JOIN product_types pt
	ON p.stock_num = pt.stock_num
JOIN items i
	ON p.stock_num = i.stock_num AND p.manu_code = i.manu_code
JOIN orders o 
	ON i.order_num = o.order_num
WHERE 
	(LEN(m.manu_code) = 3 AND (LEFT(m.manu_code, 1) = 'A' OR LEFT(m.manu_code, 1) = 'N')) AND 
	(LOWER(pt.description) LIKE '%tennis%' OR LOWER(pt.description) LIKE '%ball%')
GROUP BY 
	m.manu_code, 
	m.manu_name
HAVING 
	SUM(i.quantity * i.unit_price) > (
		SELECT 
			AVG(subtotal)
		FROM 
			(
				SELECT 
					SUM(it.quantity * it.unit_price) AS subtotal
				FROM 
					manufact mf
				JOIN products pr
					ON mf.manu_code = pr.manu_code
				JOIN items it 
					ON pr.stock_num = it.stock_num AND pr.manu_code = it.manu_code
				GROUP BY mf.manu_code
			) AS ventas_por_fabricante
		)
ORDER BY 
	monto_total_prod_vendidos DESC;



/*Ejercicio 3: 
Crear una vista que devuelva
Para cada cliente mostrar (customer_num, lname, company), cantidad de órdenes
de compra, fecha de su última OC, monto total comprado y el total general
comprado por todos los clientes.
De los clientes que posean órdenes sólo se podrán mostrar los clientes que tengan
alguna orden que posea productos que son fabricados por más de dos fabricantes y
que tengan al menos 3 órdenes de compra.
Ordenar el reporte de tal forma que primero aparezcan los clientes que tengan
órdenes por cantidad de órdenes descendente y luego los clientes que no tengan
órdenes.
*/

CREATE VIEW vista_cliente_ordenes AS
SELECT 
    c.customer_num,
    c.lname,
    c.company,
    COUNT(o.order_num) AS cantidad_ordenes,
    MAX(o.order_date) AS ultima_oc,
    SUM(i.unit_price * i.quantity) AS monto_total_comprado,
    (SELECT 
		SUM(i2.unit_price * i2.quantity)
     FROM 
		items i2
     JOIN orders o2 ON i2.order_num = o2.order_num) AS total_general_comprado
FROM 
    customer c
LEFT JOIN orders o ON c.customer_num = o.customer_num
LEFT JOIN items i ON o.order_num = i.order_num
LEFT JOIN products p ON i.stock_num = p.stock_num
LEFT JOIN manufact m ON p.manu_code = m.manu_code
GROUP BY 
    c.customer_num, 
	c.lname, 
	c.company
HAVING 
    COUNT(o.order_num) >= 3
    AND COUNT(DISTINCT m.manu_code) > 2;


SELECT 
	* 
FROM 
	vista_cliente_ordenes
ORDER BY 
	cantidad_ordenes DESC, 
	customer_num;


/*Ejercicio 4: 
Crear una consulta que devuelva los 5 primeros estados y el tipo de producto
(description) más comprado en ese estado (state) según la cantidad vendida del tipo
de producto.
Ordenarlo por la cantidad vendida en forma descendente.
Nota: No se permite utilizar funciones, ni tablas temporales.
*/

SELECT TOP 5
    c.state,
    pt.description AS tipo_producto,
    SUM(i.quantity) AS cantidad_vendida
FROM
    items i
JOIN orders o ON i.order_num = o.order_num
JOIN products p ON i.stock_num = p.stock_num
JOIN product_types pt ON p.stock_num = pt.stock_num
JOIN customer c ON o.customer_num = c.customer_num
GROUP BY 
    c.state, pt.description
ORDER BY 
    cantidad_vendida DESC;


/*Ejercicio 5: Listar los customers que no posean órdenes de compra y aquellos cuyas últimas
órdenes de compra superen el promedio de todas las anteriores.
Mostrar customer_num, fname, lname, paid_date y el monto total de la orden que
supere el promedio de las anteriores. Ordenar el resultado por monto total en forma
descendiente.*/



/*Ejercicio 6: Se desean saber los fabricantes que vendieron mayor cantidad de un mismo
producto que la competencia según la cantidad vendida. Tener en cuenta que puede
existir un producto que no sea fabricado por ningún otro fabricante y que puede
haber varios fabricantes que tengan la misma cantidad máxima vendida.
Mostrar el código del producto, descripción del producto, código de fabricante,
cantidad vendida, monto total vendido. Ordenar el resultado código de producto, por
cantidad total vendida y por monto total, ambos en forma decreciente.
Nota: No se permiten utilizar funciones, ni tablas temporales.*/

SELECT 
	p.stock_num, 
	pt.description, 
	m.manu_code, 
	SUM(i.quantity) AS cant_vendida, 
	SUM(i.unit_price * i.quantity) AS monto_total_vendido
FROM 
	items i
JOIN products p ON i.stock_num = p.stock_num
JOIN product_types pt ON p.stock_num = pt.stock_num
JOIN manufact m ON p.manu_code = m.manu_code
JOIN orders o ON i.order_num = o.order_num
GROUP BY 
	p.stock_num, 
	pt.description, 
	m.manu_code
HAVING 
	SUM(i.quantity) = (
        SELECT 
			MAX(SUM(i2.quantity))
        FROM 
			items i2
        JOIN products p2 ON i2.stock_num = p2.stock_num
        WHERE 
			p2.stock_num = p.stock_num
        GROUP BY 
			i2.stock_num,
			i2.manu_code
    )
ORDER BY 
    p.stock_num DESC, 
	cant_vendida DESC, 
	monto_total_vendido DESC;


