/*Ejercicio 1: 
	Listar Número de Cliente, apellido y nombre, Total Comprado por el cliente ‘Total del Cliente’,
	Cantidad de Órdenes de Compra del cliente ‘OCs del Cliente’ y la Cant. de Órdenes de Compra
	solicitadas por todos los clientes ‘Cant. Total OC’, de todos aquellos clientes cuyo promedio de compra
	por Orden supere al promedio de órdenes de compra general, tengan al menos 2 órdenes y cuyo
	zipcode comience con 94.
*/

SELECT 
	c.customer_num, 
	c.lname,
	c.fname, 
	SUM(i.quantity * i.unit_price) AS total_del_cliente,
	COUNT(o.order_num) AS OCs_del_cliente, 
	(SELECT COUNT(*) FROM orders) AS Cant_Total_OC
FROM 
	customer c
	JOIN orders o ON c.customer_num = o.customer_num
	JOIN items i ON i.order_num = o.order_num
WHERE 
	c.zipcode LIKE '%94'
GROUP BY 
	c.customer_num, 
	c.lname, 
	c.fname 
HAVING 
	COUNT(o.order_num) >= 2 AND 
	(SUM(i.quantity * i.unit_price) / COUNT(o.order_num)) > 
	(
		SELECT 
			AVG(i2.quantity * i2.unit_price) 
		FROM 
			orders o2 
			JOIN items i2 ON o2.order_num = i2.order_num
	)
ORDER BY
	c.customer_num; 


/*Ejercicio 2: 
	Se requiere crear una tabla temporal #ABC_Productos un ABC de Productos ordenado por cantidad
	de venta en u$, los datos solicitados son:
	Nro. de Stock, Código de fabricante, descripción del producto, Nombre de Fabricante, Total del producto
	pedido 'u$ por Producto', Cant. de producto pedido 'Unid. por Producto', para los productos que
	pertenezcan a fabricantes que fabriquen al menos 10 productos diferentes.
*/

CREATE TABLE #ABC_Productos (
    stock_num VARCHAR(50),
    manufacturer_code VARCHAR(50),
    product_description VARCHAR(255),
    manufacturer_name VARCHAR(100),
    total_product_value DECIMAL(10, 2),
    product_quantity INT
);

INSERT INTO #ABC_Productos (stock_num, manufacturer_code, product_description, manufacturer_name, total_product_value, product_quantity)
SELECT 
	i.stock_num, 
	m.manu_code, 
	pt.description,
	m.manu_name, 
	(i.quantity * i.unit_price) AS total_product_value, 
	i.quantity AS product_quantity
FROM 
	items i
	JOIN products p ON i.stock_num = p.stock_num
	JOIN product_types pt ON p.stock_num = pt.stock_num
	JOIN manufact m ON p.manu_code = m.manu_code
WHERE 
	p.manu_code IN (
		SELECT 
			p.manu_code
		FROM 
			products p
		GROUP BY 
			p.manu_code
		HAVING 
			COUNT(DISTINCT p.stock_num) >= 10
	)
ORDER BY 
	total_product_value DESC; 

-- MUESTRO TABLA TEMPORAL
SELECT * FROM #ABC_Productos


/*Ejercicio 3: 
	En función a la tabla temporal generada en el punto 2, obtener un listado que detalle para cada tipo
	de producto existente en #ABC_Producto, la descripción del producto, el mes en el que fue solicitado, el
	cliente que lo solicitó (en formato 'Apellido, Nombre'), la cantidad de órdenes de compra 'Cant OC por
	mes', la cantidad del producto solicitado 'Unid Producto por mes' y el total en u$ solicitado 'u$ Producto
	por mes'.
	Mostrar sólo aquellos clientes que vivan en el estado con mayor cantidad de clientes, ordenado por
	mes y descripción del tipo de producto en forma ascendente y por cantidad de productos por mes en
	forma descendente.
*/

SELECT 
    ap.product_description, 
    MONTH(o.order_date) AS mes_solicitado, 
    CONCAT(c.lname, ', ', c.fname) AS cliente, 
    COUNT(o.order_num) AS Cant_OC_por_MES, 
    SUM(i.quantity) AS Unid_Producto_Por_Mes, 
    SUM(i.quantity * i.unit_price) AS u$_Producto_Por_Mes
FROM 
    #ABC_Productos ap
    JOIN items i ON ap.stock_num = i.stock_num
    JOIN orders o ON i.order_num = o.order_num
    JOIN customer c ON o.customer_num = c.customer_num
    JOIN product_types pt ON ap.stock_num = pt.stock_num
GROUP BY 
    ap.product_description,
    MONTH(o.order_date),
    c.lname,
    c.fname,
    c.state
HAVING 
    c.state = (
        SELECT TOP 1 state
        FROM customer
        GROUP BY state
        ORDER BY COUNT(*) DESC
    )
ORDER BY
    mes_solicitado ASC,
    ap.product_description ASC,
    Unid_Producto_Por_Mes DESC;

/*Ejercicio 4: 
	Dado los productos con número de stock 5, 6 y 9 del fabricante 'ANZ' listar de a pares los clientes que
	hayan solicitado el mismo producto, siempre y cuando, el primer cliente haya solicitado más cantidad
	del producto que el 2do cliente.
	Se deberá informar nro de stock, código de fabricante, Nro de Cliente y Apellido del primer cliente, Nro
	de cliente y apellido del 2do cliente ordenado por stock_num y manu_code
*/
SELECT 
	i.stock_num, 
	i.manu_code, 
	c1.customer_num AS Cliente1_Nro, 
	c1.lname AS Cliente1_Apellido, 
	c2.customer_num AS Cliente2_Nro, 
	c2.lname AS Cliente2_Apellido
FROM 
	items i
	JOIN orders o1 ON i.order_num = o1.order_num
    JOIN customer c1 ON o1.customer_num = c1.customer_num
    JOIN orders o2 ON i.order_num = o2.order_num
    JOIN customer c2 ON o2.customer_num = c2.customer_num
WHERE 
	i.stock_num = 5 AND 
	i.stock_num = 6 AND 
	i.stock_num = 9 AND 
	i.manu_code = 'ANZ' AND 
	c1.customer_num < c2.customer_num
GROUP BY 
	i.stock_num,
    i.manu_code,
    c1.customer_num, c1.lname,
    c2.customer_num, c2.lname
HAVING 
	SUM(CASE WHEN o1.customer_num = c1.customer_num THEN i.quantity ELSE 0 END) > 
	SUM(CASE WHEN o2.customer_num = c2.customer_num THEN i.quantity ELSE 0 END)
ORDER BY 
	i.stock_num, 
	i.manu_code;

/*Ejercicio 5: 
	Se requiere realizar una consulta que devuelva en una fila la siguiente información: La mayor cantidad de
	órdenes de compra de un cliente, mayor total en u$ solicitado por un cliente y la mayor cantidad de
	productos solicitados por un cliente, la menor cantidad de órdenes de compra de un cliente, el menor total
	en u$ solicitado por un cliente y la menor cantidad de productos solicitados por un cliente
	Los valores máximos y mínimos solicitados deberán corresponderse a los datos de clientes según todas
	las órdenes existentes, sin importar a que cliente corresponda el dato. 
*/
SELECT 
    MAX(Cant_OC_por_Cliente) AS Mayor_Cant_OC_por_Cliente,
    MAX(Total_u$_por_Cliente) AS Mayor_Total_u$_por_Cliente,
    MAX(Cant_Productos_por_Cliente) AS Mayor_Cant_Productos_por_Cliente,
    MIN(Cant_OC_por_Cliente) AS Menor_Cant_OC_por_Cliente,
    MIN(Total_u$_por_Cliente) AS Menor_Total_u$_por_Cliente,
    MIN(Cant_Productos_por_Cliente) AS Menor_Cant_Productos_por_Cliente
FROM (
    SELECT 
        c.customer_num,
        COUNT(o.order_num) AS Cant_OC_por_Cliente,
        SUM(i.quantity * i.unit_price) AS Total_u$_por_Cliente,
        SUM(i.quantity) AS Cant_Productos_por_Cliente
    FROM 
        customer c
        JOIN orders o ON c.customer_num = o.customer_num
        JOIN items i ON o.order_num = i.order_num
    GROUP BY 
        c.customer_num
) AS cliente_stats;

/*Ejercicio 6: 
	 Seleccionar los número de cliente, número de orden y monto total de la orden de aquellos clientes del
	estado California(CA) que posean 4 o más órdenes de compra emitidas en el 2015. Además las órdenes
	mostradas deberán cumplir con la salvedad que la cantidad de líneas de ítems de esas órdenes debe ser
	mayor a la cantidad de líneas de ítems de la orden de compra con mayor cantidad de ítems del estado AZ
	en el mismo año.
*/
SELECT 
	c.customer_num, 
	o.order_num, 
	SUM(i.quantity * i.unit_price) AS Monto_Total
FROM 
	customer c 
	JOIN orders o ON c.customer_num = o.customer_num
	JOIN items i ON o.order_num = i.order_num
WHERE 
	c.state = 'CA' AND 
	YEAR(o.order_date) = 2015 AND 
	o.customer_num IN (
		SELECT 
			o.customer_num
		FROM 
			orders o 
			JOIN customer c ON o.customer_num = c.customer_num
		WHERE 
			c.state = 'CA' AND 
			YEAR(o.order_date) = 2015 
		GROUP BY 
			o.customer_num
		HAVING 
			COUNT(o.order_num) >= 4
	) 
	AND (
		SELECT 
			COUNT(i2.item_num)
        FROM 
			items i2
        WHERE 
			i2.order_num = o.order_num
	) > (
		SELECT
			MAX(item_count)
			FROM (
				SELECT 
					COUNT(i2.item_num) AS item_count
				FROM 
					orders o2
					JOIN items i2 ON o2.order_num = i2.order_num
					JOIN customer c2 ON o2.customer_num = c2.customer_num
				WHERE 
					c2.state = 'AZ' AND 
					YEAR(o2.order_date) = 2015 
				GROUP BY 
					o2.order_num
			) AS max_items
		)
GROUP BY 
	c.customer_num,
    o.order_num
ORDER BY 
    c.customer_num, 
    o.order_num;


/*Ejercicio 7: 
	Se requiere listar para el Estado de California el par de clientes que sean los que suman el mayor
	monto en dólares en órdenes de compra, con el formato de salida:
	'Código Estado', 'Descripción Estado', 'Apellido, Nombre', 'Apellido, Nombre', 'Total Solicitado' (*)
	(*) El total solicitado contendrá la suma de los dos clientes. 
*/
SELECT TOP 1
    'CA' AS Codigo_Estado, 
    'California' AS Descripcion_Estado, 
    CONCAT(c1.lname, ', ', c1.fname) AS Cliente1,
    CONCAT(c2.lname, ', ', c2.fname) AS Cliente2,
    SUM(i1.quantity * i1.unit_price + i2.quantity * i2.unit_price) AS Total_Solicitado
FROM 
    customer c1
    JOIN orders o1 ON c1.customer_num = o1.customer_num
    JOIN items i1 ON o1.order_num = i1.order_num
    JOIN customer c2 ON c1.customer_num < c2.customer_num
    JOIN orders o2 ON c2.customer_num = o2.customer_num
    JOIN items i2 ON o2.order_num = i2.order_num
WHERE 
    c1.state = 'CA' 
    AND c2.state = 'CA'
GROUP BY
    c1.customer_num, c2.customer_num, c1.lname, c1.fname, c2.lname, c2.fname
ORDER BY 
    Total_Solicitado DESC

/*Ejercicio 8: 
	Se observa que no se cuenta con stock suficiente para las últimas 5 órdenes de compra emitidas que
	contengan productos del fabricante 'ANZ'. Por lo que se decide asignarle productos en stock a la orden
	del cliente que más cantidad de productos del fabricante 'ANZ' nos haya comprado.
	Se solicita listar el número de orden de compra, número de cliente, fecha de la orden y una fecha de
	orden “modificada” a la cual se le suma el lead_time del fabricante más 1 día por preparación del pedido
	a aquellos clientes que no son prioritarios. Para aquellos clientes a los que les entregamos los productos
	en stock, la “fecha modificada” deberá estar en NULL.
	Listar toda la información ordenada por “fecha modificada”
*/