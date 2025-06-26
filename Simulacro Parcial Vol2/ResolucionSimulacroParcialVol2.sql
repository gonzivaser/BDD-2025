/* 
	1) Ejercicio 3. Query
	Por cada estado (state) seleccionar los dos clientes que mayores montos compraron. Se
	deberá mostrar el código del estado, nro de cliente, nombre y apellido del cliente y monto total
	comprado.
	Mostrar la información ordenada por provincia y por monto comprado en forma descendente.
	Notas: No se puede usar Store procedures, ni funciones de usuarios, ni tablas temporales.
*/

SELECT 
    c1.state, 
    c1.customer_num, 
    c1.fname, 
    c1.lname,
    SUM(i1.quantity * i1.unit_price) AS monto_total
FROM 
    customer c1 
    JOIN orders o1 ON c1.customer_num = o1.customer_num
    JOIN items i1 ON o1.order_num = i1.order_num
WHERE 
    c1.customer_num IN (
        SELECT TOP 2 c2.customer_num
        FROM 
            customer c2 
            JOIN orders o2 ON c2.customer_num = o2.customer_num
            JOIN items i2 ON o2.order_num = i2.order_num
        WHERE 
            c2.state = c1.state
        GROUP BY 
            c2.customer_num
        ORDER BY 
            SUM(i2.quantity * i2.unit_price) DESC
    )
GROUP BY
    c1.state, 
    c1.customer_num, 
    c1.fname, 
    c1.lname
ORDER BY 
    c1.state,
    monto_total DESC;


	