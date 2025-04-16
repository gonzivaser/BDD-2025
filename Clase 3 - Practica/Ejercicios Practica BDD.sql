-- EJERCICIO DE CLASE
SELECT 
    fname, 
    UPPER(lname) AS apellido, 
    customer_num, 
    adress1, 
    city, 
    zipcode
FROM 
    customer 
WHERE
    state = 'CA' and zipcoe LIKE '%025'


-- EJERCICIO 2
SELECT 
    manu_code, 
    COUNT(DISTINCT orden_num) AS cantOrdenes,
    SUM(quantity) AS total_quantity, 
    SUM(unit_price) AS total_unit_price, 
    SUM(unit_price * quantity) AS total_comprado
FROM 
    items 
GROUP BY 
    manu_code
HAVING
    COUNT(*) > 5
ORDER BY
    total_comprado DESC



--------------------------------------------- PRACTICA CLASE PDF ----------------------------------------------------
-- EJ 1: Obtener un listado de todos los clientes y sus direcciones.
SELECT 
    customer_num AS numero_cliente, 
    adress1 AS direccion1, 
    adress2 as direccion2, 
FROM 
    customer


-- EJ 2: Obtener el listado anterior pero sólo los clientes que viven en el estado de California “CA”.
SELECT 
    customer_num AS numero_cliente, 
    adress1 AS direccion1, 
    adress2 as direccion2, 
FROM 
    customer 
WHERE 
    state = 'CA'


-- EJ 3: Listar todas las ciudades (city) de la tabla clientes que pertenecen al estado de “CA”, mostrar sólo una vez cada ciudad.
SELECT 
    DISTINCT city AS ciudad
FROM 
    customer 
WHERE 
    state = 'CA'


-- EJ 4: Ordenar la lista anterior alfabéticamente.
SELECT 
    DISTINCT city AS ciudad
FROM 
    customer 
WHERE 
    state = 'CA'
ORDER BY
    city ASC

-- EJ 5: Mostrar la dirección sólo del cliente 103. (customer_num)
SELECT 
    adress1 
FROM 
    customer
WHERE
    customer_num = 103


-- EJ 6: Mostrar la lista de productos que fabrica el fabricante “ANZ” ordenada por el campo Código de Unidad de Medida. (unit_code)
SELECT * 
FROM 
    products
WHERE 
    manu_code = "ANZ"
ORDER BY
    unit_code ASC


-- EJ 7: Listar los códigos de fabricantes que tengan alguna orden de pedido ingresada, ordenados alfabéticamente y no repetidos.
SELECT 
    DISTINCT manu_code
FROM 
    items 
WHERE 
    order_num IS NOT NULL
ORDER BY 
    manu_code ASC


-- EJ8: Escribir una sentencia SELECT que devuelva el número de orden, fecha de orden, número de cliente y fecha
-- de embarque de todas las órdenes que no han sido pagadas (paid_date es nulo), pero fueron embarcadas
-- (ship_date) durante los primeros seis meses de 2015.
SELECT 
    order_num,
    order_date, 
    customer_num,
FROM 
    orders
WHERE 
    paid_date IS NULL AND ship_date BETWEEN '2015-01-01' AND '2015-06-30'

-- EJ 9: Obtener de la tabla cliente (customer) los número de clientes y nombres de las compañías, cuyos nombres de compañías contengan la palabra “town”.
SELECT 
    customer_num, 
    company
FROM
    customer 
WHERE 
    company LIKE '%town%';


-- EJ 10: Obtener el precio máximo, mínimo y precio promedio pagado (ship_charge) por todos los embarques. Se pide obtener la información de la tabla ordenes (orders).
SELECT
    MAX(ship_charge) AS precio_maximo, 
    MIN(ship_charge) AS precio_minimo, 
    AVG(ship_charge) AS precio_promedio
FROM 
    orders

-- EJ 11: Realizar una consulta que muestre el número de orden, fecha de orden y fecha de embarque de todas que
-- fueron embarcadas (ship_date) en el mismo mes que fue dada de alta la orden (order_date).
SELECT 
    order_num, 
    order_date, 
    ship_date
FROM 
    orders 
WHERE 
    MONTH (ship_date) = MONTH (order_date)
    

-- EJ 12: Obtener la Cantidad de embarques y Costo total (ship_charge) del embarque por número de cliente y
-- por fecha de embarque. Ordenar los resultados por el total de costo en orden inverso
SELECT 
    customer_num, 
    ship_date, 
    COUNT(*) AS cantidad_embarques, 
    SUM(ship_charge) AS costo_total
FROM 
    orders
GROUP BY
    customer_num, 
    ship_date
ORDER BY 
    costo_total DESC


-- EJ 13: Mostrar fecha de embarque (ship_date) y cantidad total de libras (ship_weight) por día, de aquellos
-- días cuyo peso de los embarques superen las 30 libras. Ordenar el resultado por el total de libras en orden
-- descendente. 
SELECT 
    ship_date, 
    SUM(ship_weight) AS peso_total, 
FROM 
    orders
GROUP BY 
    ship_date
HAVING 
    SUM(ship_weight) > 30 
ORDER BY 
    peso_total DESC


-- EJ 14: 14. Crear una consulta que liste todos los clientes que vivan en California ordenados por compañía.
SELECT *
FROM 
    customer 
WHERE 
    state = 'CA'
ORDER BY 
    company ASC


-- EJ 15: Obtener un listado de la cantidad de productos únicos comprados a cada fabricante, en donde el total
-- comprado a cada fabricante sea mayor a 1500. El listado deberá estar ordenado por cantidad de productos
-- comprados de mayor a menor.
SELECT 
    manu_code AS numero_fabricante, 
    COUNT(*) AS cantidad_productos,
    SUM(stock_num) AS cantidad_comprado
FROM 
    products 
GROUP BY 
    manu_code
HAVING 
    SUM(stock_num) > 1500
ORDER BY
    cantidad_productos DESC 


-- EJ 16:  Obtener un listado con el código de fabricante, nro de producto, la cantidad vendida (quantity), y el total
-- vendido (quantity x unit_price), para los fabricantes cuyo código tiene una “R” como segunda letra. Ordenar
-- el listado por código de fabricante y nro de producto.
SELECT 
    manu_code AS codigo_fabricante, 
    stock_num AS codigo_producto, 
    SUM(quantity) AS cantidad_vendida, 
    SUM(quantity * unit_price) AS total_vendido
FROM 
    items 
WHERE 
    manu_code LIKE '_R%'
GROUP BY 
    manu_code, 
    stock_num
ORDER BY
    manu_code, 
    stock_num


-- EJ 17: Crear una tabla temporal OrdenesTemp que contenga las siguientes columnas: cantidad de órdenes por
-- cada cliente, primera y última fecha de orden de compra (order_date) del cliente. 
-- Realizar una consulta de la tabla temp OrdenesTemp en donde la primer fecha de compra sea anterior a '2015-05-23 00:00:00.000',
-- ordenada por fechaUltimaCompra en forma descendente.
CREATE TEMPORARY TABLE OrdenesTemp AS
SELECT 
    customer_num AS numero_cliente 
    COUNT(*) AS cantidad_ordenes
    MIN(order_date) AS primera_compra
    MAX(order_date) AS ultima_compra
FROM 
    orders
GROUP BY
    customer_num

-- CONSULTA: 
SELECT 
    numero_cliente,
    cantidad_ordenes, 
    primera_compra, 
    ultima_compra
FROM 
    OrdenesTemp
WHERE 
    primera_compra < '2015-05-23 00:00:00.000'
GROUP BY 
    fechaUltimaCompra
ORDER BY
    fechaUltimaCompra DESC


-- EJ 20: Se desea obtener la cantidad de clientes por cada state y city, donde los clientes contengan el string  
-- ‘ts’ en el nombre de compañía, el código postal este entre 93000 y 94100 y la ciudad no sea 'Mountain View'. Se 
-- desea el listado ordenado por ciudad
SELECT 
    state, 
    city, 
    COUNT(*) AS cantidad_clientes
FROM 
    customer 
WHERE 
    company LIKE '%ts' AND 
    zipcode BETWEEN '93000' AND '94100' AND 
    city != 'Mountain View'
GROUP BY 
    state, 
    city
ORDER BY 
    city ASC
