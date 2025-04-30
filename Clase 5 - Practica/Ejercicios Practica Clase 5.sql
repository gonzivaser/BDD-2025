-- EJERCICIO 1: Obtener el número de cliente, la compañía, y número de orden de todos los clientes que tengan
-- órdenes. Ordenar el resultado por número de cliente. 
SELECT
    c.customer_num,
    c.company, 
    o.order_num
FROM 
    customer c 
JOIN 
    orders o ON c.customer_num = o.customer_num
ORDER BY 
    c.customer_num;

/* EJERCICIO 2:
    Listar los ítems de la orden número 1004, incluyendo una descripción de cada uno. El listado debe
    contener: Número de orden (order_num), Número de Item (item_num), Descripción del producto
    (product_types.description), Código del fabricante (manu_code), Cantidad (quantity), Precio total
    (unit_price*quantity). 
*/
SELECT 
    i.order_num, 
    i.item_num, 
    pt.description AS product_description
    i.manu_code, 
    i.quantity, 
    i.unit_price * i.quantity AS total_price
FROM 
    items i
JOIN 
    product_types pt ON i.stock_num = pt.stock_num
WHERE 
    i.order_num = 1004;

/* EJERCICIO 3:
    Listar los items de la orden número 1004, incluyendo una descripción de cada uno. El listado debe
    contener: Número de orden (order_num), Número de Item (item_num), Descripción del Producto
    (product_types.description), Código del fabricante (manu_code), Cantidad (quantity), precio total
    (unit_price*quantity) y Nombre del fabricante (manu_name). 
*/
SELECT 
    i.order_num, 
    i.item_num, 
    pt.description AS product_description
    i.manu_code, 
    i.quantity, 
    i.unit_price * i.quantity AS total_price
    m.manu_name 
FROM 
    items i
JOIN 
    product_types pt ON i.stock_num = pt.stock_num
JOIN 
    manufact m ON i.manu_code = m.manu_code
WHERE 
    i.order_num = 1004;

/* EJERCICIO 4:
    Se desea listar todos los clientes que posean órdenes de compra. Los datos a listar son los
    siguientes: número de orden, número de cliente, nombre, apellido y compañía. 
*/
SELECT 
    o.order_num, 
    c.customer_num, 
    c.fname, 
    c.lname, 
    c.company
FROM 
    orders o
JOIN 
    customer c ON o.customer_num = c.customer_num 


/* EJERCICIO 5: 
     Se desea listar todos los clientes que posean órdenes de compra. Los datos a listar son los
    siguientes: número de cliente, nombre, apellido y compañía. Se requiere sólo una fila por cliente. 
*/
SELECT DISTINCT
    o.order_num, 
    c.customer_num, 
    c.fname, 
    c.lname, 
    c.company
FROM 
    orders o
JOIN 
    customer c ON o.customer_num = c.customer_num 

/* EJERCICIO 6: 
    Se requiere listar para armar una nueva lista de precios los siguientes datos: nombre del fabricante
    (manu_name), número de stock (stock_num), descripción
    (product_types.description), unidad (units.unit), precio unitario (unit_price) y Precio Junio (precio
    unitario + 20%). 
*/
SELECT 
    m.manu_name, 
    p.stock_num,
    pt.description, 
    u.unit, 
    p.unit_price, 
    p.unit_price + (0.2 * p.unit_price) AS precio_junio
FROM 
    products p
JOIN 
    manufact m ON p.manu_code = m.manu_code
JOIN 
    product_types pt ON p.stock_num = pt.stock_num
JOIN 
    units u ON p.unit_code = u.unit_code

/* EJERCICIO 7:
    Se requiere un listado de los items de la orden de pedido Nro. 1004 con los siguientes datos:
    Número de item (item_num), descripción de cada producto
    (product_types.description), cantidad (quantity) y precio total (unit_price*quantity). 
*/
SELECT 
    i.item_num, 
    pt.description, 
    i.quantity, 
    (i.unit_price * i.quantity) AS precio_total
FROM 
    items i
JOIN 
    product_types pt ON i.stock_num = pt.stock_num
WHERE 
    i.order_num = 1004;

/* EJERCICIO 8:
    Informar el nombre del fabricante (manu_name) y el tiempo de envío (lead_time) de los ítems de
    las Órdenes del cliente 104. 
*/
SELECT 
    m.manu_name, 
    m.lead_time, 
FROM 
    items i
JOIN 
    manufact m ON i.manu_code = m.manu_code
JOIN 
    orders o ON i.order_num = o.order_num
WHERE 
    o.customer_num = 104;

/* EJERCICIO 9: 
    Se requiere un listado de las todas las órdenes de pedido con los siguientes datos: Número de
    orden (order_num), fecha de la orden (order_date), número de ítem (item_num), descripción de
    cada producto (description), cantidad (quantity) y precio total (unit_price*quantity). 
*/
SELECT 
    o.order_num, 
    o.order_date, 
    i.item_num, 
    pt.description, 
    i.quantity, 
    (i.unit_price * i.quantity) AS precio_total 
FROM 
    items i 
JOIN 
    orders o ON i.order_num = o.order_num
JOIN 
    product_types pt ON i.stock_num = pt.stock_num

/* EJERCICIO 10: 
    Obtener un listado con la siguiente información: Apellido (lname) y Nombre (fname) del Cliente
    separado por coma, Número de teléfono (phone) en formato (999) 999-9999. Ordenado por
    apellido y nombre.
*/
SELECT 
  c.lname + ', ' + c.fname AS nombreCompleto,
  '(' + SUBSTRING(c.phone, 1, 3) + ') ' + 
        SUBSTRING(c.phone, 5, 3) + '-' + 
        SUBSTRING(c.phone, 9, 4) AS telefono
FROM 
    customer c
ORDER BY 
    nombreCompleto;

/* EJERCICIO 11: 
    Obtener la fecha de embarque (ship_date), Apellido (lname) y Nombre (fname) del Cliente
    separado por coma y la cantidad de órdenes del cliente. Para aquellos clientes que viven en el
    estado con descripción (sname) “California” y el código postal está entre 94000 y 94100 inclusive.
    Ordenado por fecha de embarque y, Apellido y nombre.
*/
SELECT 
    o.ship_date, 
    CONCAT(c.lname, ', ', c.fname), 
    COUNT(o.order_num) AS cantidad_ordenes
FROM
    customer c 
JOIN 
    orders o ON c.customer_num = o.customer_num
JOIN 
    state s ON c.state = s.state 
WHERE 
    c.state = 'California' AND 
    c.zipcode BETWEEN '94000' AND '94100'
GROUP BY
    o.ship_date, 
    c.lname, 
    c.fname, 
    c.customer_num
ORDER BY 
    o.ship_date, 
    c.lname, 
    c.fname;

/* EJERCICIO 12
    Obtener por cada fabricante (manu_name) y producto (description), la cantidad vendida y el
    Monto Total vendido (unit_price * quantity). Sólo se deberán mostrar los ítems de los fabricantes
    ANZ, HRO, HSK y SMT, para las órdenes correspondientes a los meses de mayo y junio del 2015.
    Ordenar el resultado por el monto total vendido de mayor a menor.
*/
SELECT 
    m.manu_name, 
    pt.product_description, 
    SUM(i.quantity) AS cantidad_vendida, 
    (i.unit_price * i.quantity) AS monto_total_vendido
FROM
    items i 
JOIN 
    manufact m ON i.manu_code = m.manu_code
JOIN 
    product_types pt ON i.stock_num = pt.stock_num
JOIN 
    orders o ON i.order_num = o.order_num
WHERE 
    m.manu_code IN ('ANZ', 'HRO', 'HSK', 'SMT')
    AND o.order_date BETWEEN '2015-05-01' AND '2015-06-30'
GROUP BY 
    m.manu_name
ORDER BY 
    monto_total_vendido DESC; 

/* EJERCICIO 13: 
    Emitir un reporte con la cantidad de unidades vendidas y el importe total por mes de productos,
    ordenado por importe total en forma descendente.
    Formato: Año/Mes Cantidad Monto_Total
*/
SELECT 
    CONCAT(YEAR(o.order_date), '/', MONTH(o.order_date)) AS Año/Mes, 
    SUM(i.quantity) AS Cantidad, 
    SUM(i.unit_price * i.quantity) AS Monto_Total
FROM 
    items i 
JOIN 
    orders o ON i.order_num = o.order_num
GROUP BY
    YEAR(o.order_date), 
    MONTH(o.order_date)
ORDER BY 
    Monto_Total DESC; 