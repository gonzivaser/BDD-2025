/*
	Ejercicio A)
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

DROP TABLE CustomerStatistics; 

-- Creo la tabla pedida 
CREATE TABLE CustomerStatistics (
	customer_num INT PRIMARY KEY, 
	ordersqty INT, 
	maxDate DATE, 
	uniqueProducts INT
);

-- Creo el Stored Procedure Pedido
DROP PROCEDURE actualizaEstadisticas
ALTER PROCEDURE actualizaEstadisticas @customer_numDES INT, @customer_numHAS INT
AS 
BEGIN 
	-- Declaro variables 
	DECLARE @customer_num INT;
	DECLARE @ordersqty INT;
	DECLARE @maxDate DATE;
	DECLARE @uniqueProducts INT;

	-- Declaro Cursor 
	DECLARE customer_cursor CURSOR FOR 
		SELECT customer_num FROM customer WHERE customer_num BETWEEN  @customer_numDES AND @customer_numHAS;

	-- Abro Cursor 
	OPEN customer_cursor; 
	FETCH
	FROM customer_cursor INTO @customer_num; 

	-- Logica en el cursor 
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Pongo valor a las variables 
		SELECT @ordersqty = COUNT(*)
		FROM orders 
		WHERE customer_num = @customer_num

		SELECT @maxDate = MAX(order_date)
		FROM orders 
		WHERE customer_num = @customer_num

		SELECT @uniqueProducts = COUNT(DISTINCT i.stock_num)
		FROM orders o 
			JOIN items i ON o.order_num = i.order_num
		WHERE o.customer_num = @customer_num


		-- Si el cliente ya existe --> Actualizamos la tabla de estadisticas 
		IF EXISTS(SELECT 1 FROM CustomerStatistics WHERE customer_num = @customer_num)
			BEGIN
				UPDATE CustomerStatistics
				SET 
					ordersqty = @ordersqty, 
					maxDate = @maxDate, 
					uniqueProducts = @uniqueProducts
				WHERE 
					customer_num = @customer_num
			END
		
		-- Si el cliente no existe en la tabla --> Inserto 
		ELSE 
			BEGIN 
				INSERT INTO CustomerStatistics(customer_num, ordersqty, maxDate, uniqueProducts)
				VALUES (@customer_num, @ordersqty, @maxDate, @uniqueProducts);
			END
		
		-- Avanzo Cursor
		FETCH customer_cursor INTO @customer_num;
	END; 


	-- Cierro Cursor 
	CLOSE customer_cursor; 
	DEALLOCATE customer_cursor;
END; 

/*Casos de Prueba*/
EXEC actualizaEstadisticas @customer_numDES = 100, @customer_numHAS = 102;
SELECT * FROM CustomerStatistics



/*
	Ejercicio B)
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

-- Creo Tablas
DROP TABLE ClientesCalifornia
SELECT * INTO ClientesCalifornia FROM customer WHERE 1 = 0
DROP TABLE ClientesNoCAAlta
SELECT * INTO ClientesNoCAAlta FROM customer WHERE 1 = 0
DROP TABLE ClientesNoCABaja
SELECT * INTO ClientesNoCABaja FROM customer WHERE 1 = 0

DROP PROCEDURE migraClientes
CREATE PROCEDURE migraClientes @customer_numDES INT, @customer_numHAS INT
AS 
BEGIN 
	-- Manejo de errores en bloque completo
	BEGIN TRY
		BEGIN TRANSACTION;

		-- Variables
		DECLARE @customer_num SMALLINT; 
		DECLARE @monto_total DECIMAL(10, 2); 
		DECLARE @state CHAR(2); 

		-- Cursor
		DECLARE customer_cursor CURSOR FOR 
			SELECT customer_num FROM customer WHERE customer_num BETWEEN @customer_numDES AND @customer_numHAS;

		OPEN customer_cursor; 
		FETCH customer_cursor INTO @customer_num; 

		WHILE @@FETCH_STATUS = 0
		BEGIN 
			-- Pongo valor a la variable monto total
			SELECT @monto_total = ISNULL(SUM(i.quantity * i.unit_price), 0)
			FROM 
				orders o 
				JOIN items i ON o.order_num = i.order_num
			WHERE o.customer_num = @customer_num

			SELECT @state = state 
			FROM customer 
			WHERE customer_num = @customer_num

			-- Aplico logica de estado de california 
			IF @state = 'CA'
				BEGIN
					INSERT INTO ClientesCalifornia 
					SELECT * FROM customer WHERE customer_num = @customer_num
				END
			ELSE IF @monto_total > 999 
				BEGIN 
					INSERT INTO ClientesNoCAAlta
					SELECT * FROM customer WHERE customer_num = @customer_num
				END
			ELSE 
				BEGIN 
					INSERT INTO ClientesNoCABaja
					SELECT * FROM customer WHERE customer_num = @customer_num
				END 

			-- Actualizo estado
			UPDATE customer 
			SET status = 'P'
			WHERE customer_num = @customer_num;

			-- Siguiente cliente
			FETCH customer_cursor INTO @customer_num;
		END

		CLOSE customer_cursor; 
		DEALLOCATE customer_cursor;

		COMMIT TRANSACTION;
	END TRY
	
	BEGIN CATCH
        ROLLBACK TRANSACTION;
			DECLARE @ErrorMsg NVARCHAR(4000);
			SET @ErrorMsg = ERROR_MESSAGE();	
			RAISERROR('Error durante la migración: %s', 16, 1, @ErrorMsg);
    END CATCH
END;

-- Casos de Prueba
-- Ejecutar el procedimiento con un rango
SELECT * FROM customer
EXEC migraClientes 101, 204;

-- Verificar resultados
SELECT * FROM ClientesCalifornia
SELECT * FROM ClientesNoCAAlta
SELECT * FROM clientesNoCABaja



/*
	Ejercicio 3) 
	Crear un procedimiento ‘actualizaPrecios’ que reciba como parámetros
	manu_codeDES, manu_codeHAS y porcActualizacion que dependiendo del tipo de
	cliente y la cantidad de órdenes genere las siguientes tablas listaPrecioMayor y
	listaPreciosMenor. Ambas tienen las misma estructura que la tabla Productos.
		• El procedimiento deberá tomar de la tabla stock todos los productos que
		correspondan al rango de fabricantes asignados por parámetro.
		Por cada producto del fabricante se evaluará la cantidad (quantity) comprada.
		Si la misma es mayor o igual a 500 se grabará el producto en la tabla
		listaPrecioMayor y el unit_price deberá ser actualizado con (unit_price *
		(porcActualización *0,80)),
		Si la cantidad comprada del producto es menor a 500 se actualizará (o insertará)
		en la tabla listaPrecioMenor y el unit_price se actualizará con (unit_price *
		porcActualizacion)
		• Asimismo, se deberá actualizar un campo status de la tabla stock con valor ‘A’
		Actualizado, para todos aquellos productos con cambio de precio actualizado.
		• El procedimiento deberá contemplar todas las operaciones de cada fabricante
		como un lote, en el caso que ocurra un error, se deberá informar el error ocurrido
		y deshacer la operación de ese fabricante.
*/

-- Creo las Tablas Pedidas
DROP TABLE listaPrecioMayor
SELECT * INTO ListaPrecioMayor FROM products WHERE 1 = 0
DROP TABLE listaPrecioMenor
SELECT * INTO ListaPrecioMenor FROM products WHERE 1 = 0

-- Creo el Stored Procedure Pedido 
DROP PROCEDURE actualizaPrecios
CREATE PROCEDURE actualizaPrecios @manu_codeDES INT, @manu_codeHAS INT, @porcActualizacion DECIMAL(5,2)
AS
BEGIN 
	-- Manejo de errores en bloque completo
	BEGIN TRY
		BEGIN TRANSACTION;

		-- Variables 
		DECLARE @manu_code CHAR(3); 
		DECLARE @unit_price DECIMAL(10,2);
		DECLARE @precio_actualizado DECIMAL(10,2);

		-- Declaro Cursor 
		DECLARE producto_cursor CURSOR FOR 
			SELECT 
				p.stock_num,
				ISNULL(SUM(i.quantity), 0) AS cant_comprada,
				p.unit_price
			FROM 
				products p
				LEFT JOIN items i ON p.stock_num = i.stock_num
			WHERE 
				p.manu_code = @manu_code

		-- Abro cursor 
		OPEN producto_cursor;
		FETCH producto_cursor INTO @stock_num, @cant_comprada, @unit_price;

		-- Logica del cursor
		WHILE @@FETCH_STATUS = 0
			
		COMMIT TRANSACTION;
	END TRY


	BEGIN CATCH
        ROLLBACK TRANSACTION;
			DECLARE @ErrorMsg NVARCHAR(4000);
			SET @ErrorMsg = ERROR_MESSAGE();	
			RAISERROR('Error durante la migración: %s', 16, 1, @ErrorMsg);
    END CATCH
END;