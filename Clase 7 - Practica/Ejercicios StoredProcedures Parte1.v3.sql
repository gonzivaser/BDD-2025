/*Ejercicio A:
Crear la siguiente tabla CustomerStatistics con los siguientes campos
customer_num (entero y pk), ordersqty (entero), maxdate (date), uniqueProducts
(entero)
Crear un procedimiento ‘actualizaEstadisticas’ que reciba dos parámetros
customer_numDES y customer_numHAS y que en base a los datos de la tabla
customer cuyo customer_num estén en en rango pasado por parámetro, inserte (si
no existe) o modifique el registro de la tabla CustomerStatistics con la siguiente
información:
Ordersqty contedrá la cantidad de órdenes para cada cliente.
Maxdate contedrá la fecha máxima de la última órde puesta por cada cliente.
uniqueProducts contendrá la cantidad única de tipos de productos adquiridos
por cada cliente.
*/

/*CREO UNA LA TABLA CUSTOMER STATISTICS*/
CREATE TABLE CustomerStatistics (
    customer_num SMALLINT PRIMARY KEY,
    ordersqty INT,
    maxdate DATE,
    uniqueProducts INT
);

/*CREO EL STORED PROCEDURE PEDIDO*/
CREATE PROCEDURE actualizarEstadisticas 
@customer_numDES INT, 
@customer_numHAS INT
AS
BEGIN 
	DECLARE @current_customer_num INT;

	-- DECLARO CURSOR 
	DECLARE customer_cursor CURSOR FOR 
		SELECT 
			customer_num
		FROM 
			customer 
		WHERE 
			customer_num BETWEEN @customer_numDES AND @customer_numHAS;

	OPEN customer_cursor; 

	FETCH NEXT FROM customer_cursor INTO @current_customer_num; 

	WHILE @@FETCH_STATUS = 0
	BEGIN 
		IF EXISTS (SELECT * FROM CustomerStatistics WHERE customer_num = @current_customer_num)
		BEGIN 
			UPDATE 
				CustomerStatistics
			SET 
				ordersqty = (SELECT COUNT(DISTINCT o.order_num)
							FROM orders o
							WHERE o.customer_num = @current_customer_num
				),
				maxdate = (SELECT MAX(o.order_date)
							FROM orders o 
							WHERE o.customer_num = @current_customer_num
				),
				uniqueProducts = (SELECT COUNT(DISTINCT i.stock_num)
                                  FROM items i
                                  JOIN orders o ON i.order_num = o.order_num
                                  WHERE o.customer_num = @current_customer_num
				)
				WHERE customer_num = @current_customer_num
		END 
		ELSE
		BEGIN 
			INSERT INTO CustomerStatistics (customer_num, ordersqty, maxdate, uniqueProducts)
            SELECT 
                o.customer_num,
                COUNT(DISTINCT o.order_num) AS ordersqty,
                MAX(o.order_date) AS maxdate,
                COUNT(DISTINCT i.stock_num) AS uniqueProducts
            FROM 
                orders o
            JOIN 
                items i ON o.order_num = i.order_num
            WHERE 
                o.customer_num = @current_customer_num
            GROUP BY 
                o.customer_num;
		END
	
	FETCH NEXT FROM customer_cursor INTO @current_customer_num;
    END
	
	CLOSE customer_cursor;
    DEALLOCATE customer_cursor;
END;


/*CASO DE PRUEBA*/
EXEC actualizarEstadisticas 100, 200;

SELECT * FROM CustomerStatistics;




/*Ejercicio B:
	Crear un procedimiento ‘migraClientes’ que reciba dos parámetros
	customer_numDES y customer_numHAS y que dependiendo el tipo de cliente y la
	cantidad de órdenes los inserte en las tablas clientesCalifornia, clientesNoCaBaja,
	clienteNoCAAlta.

		• El procedimiento deberá migrar de la tabla customer todos los
		clientes de California a la tabla clientesCalifornia, los clientes que no
		son de California pero tienen más de 999u$ en OC en
		clientesNoCaAlta y los clientes que tiene menos de 1000u$ en OC en
		la tablas clientesNoCaBaja.
		• Se deberá actualizar un campo status en la tabla customer con valor
		‘P’ Procesado, para todos aquellos clientes migrados.
		• El procedimiento deberá contemplar toda la migración como un lote,
		en el caso que ocurra un error, se deberá informar el error ocurrido y
		abortar y deshacer la operación.
*/