/* EJERCICIO 1:
    Mostrar el Código del fabricante, nombre del fabricante, tiempo de entrega y monto
    Total de productos vendidos, ordenado por nombre de fabricante. En caso que el
    fabricante no tenga ventas, mostrar el total en NULO.
*/

SELECT 
    m.manu_code, 
    m.manu_name, 
    m.lead_time, 
    SUM(i.quantity * i.unit_price) AS monto_total_productos_vendidos
FROM 
    manufact m 
LEFT JOIN 
    products p ON m.manu_code = p.manu_code
LEFT JOIN 
    items i ON m.manu_code = i.manu_code AND p.stock_num = i.stock_num
GROUP BY 
    m.manu_name, 
    m.manu_code, 
    m.lead_time
ORDER BY 
    m.manu_name

/* EJERCICIO 2:
    Mostrar en una lista de a pares, el código y descripción del producto, y los pares de
    fabricantes que fabriquen el mismo producto. En el caso que haya un único fabricante
    deberá mostrar el Código de fabricante 2 en nulo. Ordenar el resultado por código de
    producto.
*/
SELECT 
    p.stock_num, 
    pt.description, 
    p1.manu_code AS fabricante_1, 
    p2.manu_code AS fabricante_2
FROM 
    product p1
JOIN 
    product_types pt ON p1.stock_num = pt.stock_num
LEFT JOIN 
    products p2 ON p1.stock_num = p2.stock_num AND 
    p1.manu_code < p2.manu_code
ORDER BY 
    p1.stock_num

/* EJERCICIO 3:
    Listar todos los clientes que hayan tenido más de una orden.
    a) En primer lugar, escribir una consulta usando una subconsulta.
    b) Reescribir la consulta utilizando GROUP BY y HAVING.
    
    La consulta deberá tener el siguiente formato:
    Número_de_Cliente Nombre Apellido
    (customer_num) (fname) (lname)
*/
-- a) 
SELECT 
    customer_num, 
    fname, 
    lname
FROM 
    customer c
WHERE 
    c.customer_num IN (
        SELECT 
            customer_num
        FROM 
            orders o 
        GROUP BY 
            o.customer_num
        HAVING 
            COUNT(o.customer_num) > 1
    );

-- b) 
SELECT 
    c.customer_num, 
    c.fname, 
    c.lname,
FROM 
    customer c 
JOIN 
    orders o ON c.customer_num = o.customer_num
GROUP BY 
    c.customer_num, 
    c.fname, 
    c.lname
HAVING 
    COUNT (*) > 1;


/* EJERCICIO 4:
    Seleccionar todas las Órdenes de compra cuyo Monto total (Suma de p x q de sus items)
    sea menor al precio total promedio (avg p x q) de todas las líneas de las ordenes.
    Formato de la salida: Nro. de Orden Total
    (order_num) (suma)
*/
SELECT 
    o.order_num, 
    SUM(i.quantity * i.unit_price) AS suma
FROM 
    orders o 
JOIN 
    items i ON o.order_num = i.order_num
GROUP BY 
    o.order_num
HAVING 
    SUM(i.quantity * i.unit_price) < 
    (
        SELECT 
            AVG(quantity * unit_price)
        FROM 
            items
    ); 

/* EJERCICIO 5:
    Obtener por cada fabricante, el listado de todos los productos de stock con precio
    unitario (unit_price) mayor que el precio unitario promedio de dicho fabricante.
    Los campos de salida serán: manu_code, manu_name, stock_num, description,
    unit_price.
*/
SELECT 
   m.manu_code, 
   m.manu_name, 
   p.stock_num, 
   pt.description, 
   p.unit_price
FROM 
    products p
JOIN 
    product_types pt ON p.stock_num = pt.stock_num
JOIN 
    manufact m ON p.manu_code = m.manu_code
WHERE 
    p.unit_price > 
    (
        SELECT 
            AVG(p2.unit_price)
        FROM 
            products p2
        WHERE 
            p2.manu_code = p.manu_code
    )

/* EJERCICIO 6:
    Usando el operador NOT EXISTS listar la información de órdenes de compra que NO
    incluyan ningún producto que contenga en su descripción el string ‘ baseball gloves’.
    Ordenar el resultado por compañía del cliente ascendente y número de orden
    descendente.
    El formato de salida deberá ser:
    Número de Cliente Compañía Número de Orden Fecha de la Orden
    (customer_num) (company) (order_num) (order_date)
*/
SELECT 
    c.customer_num, 
    c.company, 
    o.order_num, 
    o.order_date
FROM 
    customer c 
JOIN 
    orders o ON c.customer_num = o.customer_num
WHERE 
    NOT EXISTS (
        SELECT 
            1
        FROM 
            products p
        JOIN 
            items i ON p.stock_num = i.stock_num
        JOIN 
            product_types pt ON p.stock_num = pt.stock_num
        WHERE 
            p.order_num = i.order_num AND 
            pt.description LIKE '%baseball gloves%'
    )
ORDER BY 
    c.company ASC, 
    o.order_num DESC;

/* EJERCICIO 7:
    Obtener el número, nombre y apellido de los clientes que NO hayan comprado productos
    del fabricante ‘HSK’.
*/
SELECT 
    c.customer_num, 
    c.fname, 
    c.lname
FROM 
    customer 
WHERE 
    NOT EXISTS (
        SELECT 
            1
        FROM 
            orders o 
        JOIN 
            items i ON o.order_num = i.order_num 
        JOIN 
            products p ON i.stock_num = p.stock_num AND i.manu_code = p.manu_code
        WHERE 
            c.customer_num = o.order_num AND 
            p.manu_code = 'HSK'
    ); 

/* EJERCICIO 8:
    Obtener el número, nombre y apellido de los clientes que hayan comprado TODOS los
    productos del fabricante ‘HSK’.
*/
SELECT 
    c.customer_num, 
    c.fname, 
    c.lname
FROM 
    customer 
WHERE 
    NOT EXISTS (
        SELECT 
            1
        FROM 
            products p 
        WHERE 
            p.manu_code = 'HSK' AND 
            NOT EXISTS (
                SELECT 
                    1
                FROM 
                    orders o 
                JOIN 
                    items i ON o.order_num = i.order_num
                WHERE 
                    o.customer_num = c.customer_num AND 
                    i.stock_num = p.stock_num AND 
                    i.manu_code = p.manu_code
            )
    ); 

/* EJERCICIO 9:
    Reescribir la siguiente consulta utilizando el operador UNION:
    SELECT * FROM products
    WHERE manu_code = ‘HRO’ OR stock_num = 1
*/
SELECT *
FROM 
    products 
WHERE 
    manu_code = 'HRO'
UNION 
SELECT * 
FROM 
    products
WHERE 
    stock_num = 1

/* EJERCICIO 10:
    Desarrollar una consulta que devuelva las ciudades y compañías de todos los Clientes
    ordenadas alfabéticamente por Ciudad pero en la consulta deberán aparecer primero las
    compañías situadas en Redwood City y luego las demás.
    Formato: Clave de ordenamiento Ciudad Compañía
    (sortkey) (city) (company)
*/
SELECT 
    sortKey AS sortKey, 
    c.city, 
    c.company

/* EJERCICIO 11: 
    11.Desarrollar una consulta que devuelva los dos tipos de productos más vendidos y los dos
    menos vendidos en función de las unidades totales vendidas.
    Formato

    Tipo Producto Cantidad
    101 999
    189 888
    24 ...
    4 1
*/

SELECT *
FROM (
    SELECT 
        i.stock_num as Tipo_Producto,
        SUM(i.quantity) AS Cantidad 
    FROM 
        items i 
    GROUP BY 
        i.stock_num
    ORDER BY 
        SUM(i.quantity) DESC; 
    LIMIT 2
) 

UNION 

SELECT *
FROM (
    SELECT 
        i.stock_num as Tipo_Producto,
        SUM(i.quantity) AS Cantidad 
    FROM 
        items i 
    GROUP BY 
        i.stock_num
    ORDER BY 
        SUM(i.quantity) ASC; 
    LIMIT 2
) 