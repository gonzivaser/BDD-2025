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

CREATE PROCEDURE migraClientes
@customer_numDES INT, 
@customer_numHAS INT
AS
BEGIN 
	BEGIN TRY 
		BEGIN TRANSACTION; 

		-- DECLARO VARIABLES A INSERTAR EN TABLAS
		DECLARE @current_customer_num INT; 
		DECLARE @state CHAR(2); 
		DECLARE @total_oc DECIMAL(18,2); 

		-- DECLARO CURSOR
		DECLARE customer_cursor CURSOR FOR
            SELECT customer_num
            FROM customer
            WHERE customer_num BETWEEN @customer_numDES AND @customer_numHAS;

		-- ABRO CURSOR 
		OPEN customer_cursor;
        FETCH NEXT FROM customer_cursor INTO @current_customer_num;

        WHILE @@FETCH_STATUS = 0
		BEGIN 
			-- OBTENGO EL ESTADO Y EL TOTAL DE LAS ORDENES 
			SELECT 
				@state = state
			FROM 
				customer 
			WHERE 
				customer_num = @current_customer_num

			SELECT 
				@total_oc = SUM(ISNULL(o.ship_charge,0))
			FROM 
				orders o
			WHERE 
				o.customer_num = @current_customer_num

			-- SI EL CLIENTE ES DE CALIFORNIA 
			IF @state = 'CA'
			BEGIN 
				INSERT INTO clientesCalifornia 
				SELECT * FROM customer WHERE customer_num = @current_customer_num;
			END 
			-- SI NO ES DE CALIFORNIA PERO TOTAL > 999
			ELSE 
			BEGIN 
			IF @total_oc > 999
			BEGIN 
				INSERT INTO clientesNoCaAlta
				SELECT * FROM customer WHERE customer_num = @current_customer_num;
			END 
			-- SI NO ES DE CALIFORNIA PERO TOTAL < 999
			ELSE 
			BEGIN 
				INSERT INTO clientesNoCaBaja 
				SELECT * FROM customer WHERE customer_num = @current_customer_num;
			END 
			END 

			-- HAGO EL UPDATE DE LA TABLA CUSTOMER EN EL ATRIBUTO STATUS
			UPDATE customer 
			SET status = 'P'
			WHERE customer_num = @current_customer_num;

		-- AVANZO EL CURSOR 
		FETCH NEXT FROM customer_cursor INTO @current_customer_num;
	END

	CLOSE customer_cursor; 
	DEALLOCATE customer_cursor; 
	COMMIT TRANSACTION; 
	END TRY

    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error durante la migración: %s', 16, 1, @ErrorMessage);
    END CATCH

END;


/*CASOS DE PRUEBA*/
-- Tabla para clientes de California
CREATE TABLE clientesCalifornia (
    customer_num SMALLINT PRIMARY KEY,
    fname VARCHAR(15),
    lname VARCHAR(15),
    company VARCHAR(20),
    address1 VARCHAR(20),
    address2 VARCHAR(20),
    city VARCHAR(15),
    state CHAR(2),
    zipcode CHAR(5),
    phone VARCHAR(18),
    customer_num_referedBy SMALLINT,
    status CHAR(1)
);

-- Tabla para clientes fuera de CA con más de 999u$
CREATE TABLE clientesNoCaAlta (
    customer_num SMALLINT PRIMARY KEY,
    fname VARCHAR(15),
    lname VARCHAR(15),
    company VARCHAR(20),
    address1 VARCHAR(20),
    address2 VARCHAR(20),
    city VARCHAR(15),
    state CHAR(2),
    zipcode CHAR(5),
    phone VARCHAR(18),
    customer_num_referedBy SMALLINT,
    status CHAR(1)
);

-- Tabla para clientes fuera de CA con menos o igual a 999u$
CREATE TABLE clientesNoCaBaja (
    customer_num SMALLINT PRIMARY KEY,
    fname VARCHAR(15),
    lname VARCHAR(15),
    company VARCHAR(20),
    address1 VARCHAR(20),
    address2 VARCHAR(20),
    city VARCHAR(15),
    state CHAR(2),
    zipcode CHAR(5),
    phone VARCHAR(18),
    customer_num_referedBy SMALLINT,
    status CHAR(1)
);


-- Ejecutar el procedimiento con un rango
EXEC migraClientes 100, 200;

-- Verificar resultados
SELECT * FROM clientesCalifornia;
SELECT * FROM clientesNoCaAlta;
SELECT * FROM clientesNoCaBaja;
SELECT customer_num, status FROM customer WHERE customer_num BETWEEN 100 AND 200;



/*Ejercicio 3: 
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
DROP PROCEDURE actualizaPrecios;

CREATE PROCEDURE actualizaPrecios 
@manu_codeDES CHAR(3), 
@manu_codeHAS CHAR(3), 
@porcActualizacion DECIMAL(5, 2)
AS
BEGIN 
	DECLARE @current_manu CHAR(3); 
	
	-- DECLARO CURSOR
	DECLARE manu_cursor CURSOR FOR 
		SELECT DISTINCT manu_code 
		FROM products 
		WHERE manu_code BETWEEN @manu_codeDES AND @manu_codeHAS;

	OPEN manu_cursor; 
	FETCH NEXT FROM manu_cursor INTO @current_manu;

	WHILE @@FETCH_STATUS = 0
	BEGIN 
		BEGIN TRY 
			BEGIN TRANSACTION; 

			-- INSERTO PRODUCTOS EN TABLA DE LISTA POR MAYOR CON QUANTITY >= 500
			INSERT INTO listaPrecioMayor (stock_num, manu_code, unit_price, unit_code)
			SELECT 
				p.stock_num, 
				p.manu_code, 
				p.unit_price * (@porcActualizacion * 0.80),
				p.unit_code 
			FROM 
				products p
			JOIN items i ON p.stock_num = i.stock_num AND p.manu_code = i.manu_code
			WHERE 
				p.manu_code = @current_manu
			GROUP BY 
				p.stock_num, 
				p.manu_code, 
				p.unit_price, 
				p.unit_code
			HAVING 
				SUM(i.quantity) >= 500; 

			-- INSERTO PRODUCTOS EN TABLA DE LISTA POR MENOR CON QUANTITY < 500
			INSERT INTO listaPrecioMayor (stock_num, manu_code, unit_price, unit_code)
			SELECT 
				p.stock_num, 
				p.manu_code, 
				p.unit_price * @porcActualizacion,
				p.unit_code 
			FROM 
				products p
			JOIN items i ON p.stock_num = i.stock_num AND p.manu_code = i.manu_code
			WHERE 
				p.manu_code = @current_manu
			GROUP BY 
				p.stock_num, 
				p.manu_code, 
				p.unit_price, 
				p.unit_code
			HAVING 
				SUM(i.quantity) < 500; 


			-- ACTUALIZO EL STATUS EN LA TABLA ORIGINAL DE PRODUCTOS 
			UPDATE p
            SET status = 'A'
            FROM products p
            WHERE p.manu_code = @current_manu AND 
			EXISTS (
                SELECT 1
                FROM items i
                WHERE i.stock_num = p.stock_num AND i.manu_code = p.manu_code
            );

			COMMIT TRANSACTION; 

		END TRY
		BEGIN CATCH 
			ROLLBACK TRANSACTION;
            DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
            RAISERROR('Error en fabricante %s: %s', 16, 1, @current_manu, @ErrorMessage);
        END CATCH;

        FETCH NEXT FROM manu_cursor INTO @current_manu;
    END

    CLOSE manu_cursor;
    DEALLOCATE manu_cursor;
END;


/*CASOS DE PRUEBA*/
DROP TABLE listaPrecioMayor
DROP TABLE listaPrecioMenor

CREATE TABLE listaPrecioMayor (
    stock_num SMALLINT,
    manu_code CHAR(3),
    unit_price DECIMAL(10,2),
    unit_code SMALLINT
);

CREATE TABLE listaPrecioMenor (
    stock_num SMALLINT,
    manu_code CHAR(3),
    unit_price DECIMAL(10,2),
    unit_code SMALLINT
);

-- Insertar productos
INSERT INTO products (stock_num, manu_code, unit_price, unit_code, status) VALUES
(101, 'A01', 100.00, 1, NULL),
(102, 'A01', 150.00, 1, NULL),
(103, 'B01', 200.00, 1, NULL),
(104, 'B01', 300.00, 1, NULL);

-- Insertar ítems para simular ventas
INSERT INTO items (order_num, item_num, stock_num, manu_code, quantity) VALUES
-- A01 productos con ventas altas
(1, 1, 101, 'A01', 300),
(2, 1, 101, 'A01', 250),  -- Total = 550 ≥ 500

-- A01 producto con pocas ventas
(3, 1, 102, 'A01', 100),  -- Total = 100 < 500

-- B01 producto con pocas ventas
(4, 1, 103, 'B01', 200),  -- Total = 200 < 500

-- B01 producto con ventas altas
(5, 1, 104, 'B01', 600);  -- Total = 600 ≥ 500

-- Supón que quieres actualizar con 10% de incremento
EXEC actualizaPrecios 'A01', 'B01', 1.10;
