/*
	1. Explique las diferencias existentes entre una función de usuario y un stored procedure.
	Una función de usuario (user-defined function) puede ser utilizada dentro de una consulta SQL y siempre debe devolver un valor (escalar o tabla). 
	No puede modificar datos de las tablas (no puede hacer INSERT, DELETE ni UPDATE), y sí o sí tiene un parámetro de salida.
	
	Un stored procedure, en cambio, puede modificar datos y permite ejecutar múltiples sentencias 
	SQL (incluyendo INSERT, UPDATE, DELETE). No puede ser invocado directamente en una consulta SQL, 
	pero puede tener cero, uno o múltiples parámetros de salida mediante la cláusula OUTPUT.
*/

/*
	2. Detalle por lo menos 3 objetos de bases de datos relacionados con la funcionalidad de integridad. 
		Explique brevemente el uso de cada objeto para asegurar la integridad.

		1) Restricciones PRIMARY KEY
			Función: Garantiza que una columna (o conjunto de columnas) tenga valores únicos y no nulos.
			Asegura integridad: Evita duplicados y asegura que cada fila pueda identificarse de forma única.

		2) Restricciones FOREIGN KEY
			Función: Establece una relación entre dos tablas, haciendo referencia a una clave primaria de otra.
			Asegura integridad: Impide insertar registros que no tengan correspondencia en la tabla referenciada 
								(integridad referencial).

		3) Restricciones CHECK 
			Función: Limita los valores que pueden colocarse en una columna según una condición lógica.
			Asegura integridad: Evita datos inválidos o fuera de rango, por ejemplo: edad > 0.
*/

/*
	3. Query
	Crear una consulta que muestre de las tres Estados que tengan la mayor cantidad de VENTAS (no compras): 
	Nombre del Estado, monto total vendido en ese Estado, nombre del fabricante y cantidad vendida total de ese 
	fabricante en esa provincia.
	Solo se deberán mostrar en la consulta los fabricantes cuyas ventas totales superen el 15% de las ventas de su provincia.
	Ordenar el resultado por el monto total vendido del Estado de mayor a menor y por monto vendido del fabricante de manera descendente.
	Notas: Se puede utilizar SOLO UN subquery. No usar Store procedures, ni funciones de usuarios, ni tablas temporales.
*/

SELECT
	estadosConMasVentas.sname AS nombre_estado, 
	estadosConMasVentas.total_ventas_estado AS monto_total_vendido, 
	m.manu_name AS nombre_fabricante, 
	SUM(i.quantity * i.unit_price) AS total_vendido_fabricante
FROM 
	(
		SELECT TOP 3
			s.state, 
			s.sname, 
			SUM(i.quantity * i.unit_price) AS total_ventas_estado
		FROM 
			customer c 
			JOIN state s ON c.state = s.state 
			JOIN orders o ON c.customer_num = o.customer_num
			JOIN items i ON o.order_num = i.order_num
		GROUP BY 
			s.state, s.sname
		ORDER BY 
			SUM(i.quantity * i.unit_price) DESC
	) AS estadosConMasVentas
	
	JOIN customer c ON c.state = estadosConMasVentas.state
	JOIN orders o ON c.customer_num = o.customer_num
	JOIN items i ON o.order_num = i.order_num
	JOIN products p ON i.manu_code = p.manu_code
	JOIN manufact m ON p.manu_code = m.manu_code
GROUP BY 
	estadosConMasVentas.sname, estadosConMasVentas.total_ventas_estado, m.manu_name
HAVING 
	SUM(i.quantity * i.unit_price) > 0.15 * estadosConMasVentas.total_ventas_estado
ORDER BY 
	estadosConMasVentas.total_ventas_estado DESC,
	SUM(i.quantity * i.unit_price) DESC;


/*
	4. Stored Procedure
	Crear un procedimiento ResumenMensualPR que reciba una fecha como parámetro. Este Procedure deberá guardar en una 
	tabla VENTASxMES el Monto total y las cantidades totales de unidades vendidas de productos para el Año y mes (yyyymm) 
	de la fecha ingresada como parámetro.

	Dependiendo del atributo unit correspondiente a la unidad del producto las cantidades deberán ser “ajustadas” según 
	la siguiente tabla:
		Box: Se multiplica la cantidad x 12
		Case: Se multiplica la cantidad x 6
		Pair: Se multiplica la cantidad x 2
		Each: Las cantidades no se ajustan. 

	Tabla VENTASxMES
		anioMes     varchar(6) PK
		stock_num   smallint   
		manu_code	char(3)    
		Cantidad    int
		Monto       decimal(10,2)

	El procedimiento debe manejar TODO el proceso en una transacción y deshacer todas las operaciones en caso de error.
*/

CREATE TABLE VENTASxMES (
	anioMes VARCHAR(6),         
	stock_num SMALLINT,
	manu_code CHAR(3),
	Cantidad INT,
	Monto DECIMAL(10, 2),
	PRIMARY KEY (anioMes, stock_num, manu_code) 
);

CREATE OR ALTER PROCEDURE ResumenMensualPR @unaFecha DATE
AS 
BEGIN 
	-- Declaro Variables 
	DECLARE @anioMes VARCHAR(6),
			@stock_num SMALLINT, 
			@manu_code CHAR(3), 
			@Cantidad INT,
			@Monto DECIMAL(10, 2),
			@unit CHAR(4), 
			@Cantidad_Final INT; 

	-- Seteo el anioMes al formato pedido 
	SET @anioMes = FORMAT(@unaFecha, 'yyyyMM')

	-- Declaro Cursor 
	DECLARE resumenMensual_cursor CURSOR FOR 
		SELECT 
			p.stock_num, 
			p.manu_code, 
			u.unit, 
			SUM(i.quantity * i.unit_price) AS Monto,
			SUM(i.quantity) AS Cantidad
		FROM 
			products p 
			JOIN units u ON p.unit_code = u.unit_code
			JOIN items i ON p.stock_num = i.stock_num
			JOIN orders o ON i.order_num = o.order_num
		WHERE 
			YEAR(o.order_date) = YEAR(@unaFecha) AND 
			MONTH(o.order_date) = MONTH(@unaFecha)
		GROUP BY 
			p.stock_num, p.manu_code

	-- Abro Cursor 
	OPEN resumenMensual_cursor; 
	FETCH resumenMensual_cursor INTO @stock_num, @manu_code, @unit, @Monto, @Cantidad; 

	-- Logica de cursor 
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		BEGIN TRY
			BEGIN TRANSACTION
				
				-- Aplico logica de Cantidades
				IF @unit = 'Box'
					SET @Cantidad_Final = @Cantidad * 12
				ELSE IF @unit = 'Case'
					SET @Cantidad_Final = @Cantidad * 6
				ELSE IF @unit = 'Pair'
					SET @Cantidad_Final = @Cantidad * 2
				ELSE 
					SET @Cantidad_Final = @Cantidad

				-- Inserto en la tabla de VENTASxMES
				INSERT INTO VENTASxMES(stock_num, manu_code, Cantidad, Monto)
				VALUES (@stock_num, @manu_code, @Cantidad_Final, @Monto);

				-- Avanzo cursor 
				FETCH resumenMensual_cursor INTO @anioMes, @stock_num, @manu_code, @Cantidad, @Monto;
					
			COMMIT TRANSACTION

			-- Cierro Cursor 
			CLOSE resumenMensual_cursor;
			DEALLOCATE resumenMensual_cursor;
		END TRY

		BEGIN CATCH
			ROLLBACK TRANSACTION
				-- Cierro Cursor 
				CLOSE resumenMensual_cursor;
				DEALLOCATE resumenMensual_cursor;

				-- Tiro error
				DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
				RAISERROR('Error: %s', 16, 1, @ErrMsg);
		END CATCH
	END
END;


/*
	5. Trigger 
	Se cuenta con una tabla PermisosxProducto que contiene por cada customer_num los productos que este cliente puede comprar.
	La estructura de la tabla es la siguiente:
	(Customer_num, Manu_code, Stock_num)
	Se pide crear un trigger que ante la inserción de una o varias filas en la tabla ítems, valide que el customer_num de 
	la orden a la que pertenece cada ítem tenga permiso de compra sobre el producto asociado a dicho ítem (manu_code+stock_num).
	En caso que el cliente (customer_num) no tenga permisos (no exista un registro en la tabla permisosPorProducto) se 
	deberá cancelar la inserción enviando un mensaje de error y deshacer todas las operaciones realizadas
	Nota: Las inserciones pueden ser masivas.
*/

CREATE TABLE PermisosxProducto (
	customer_num SMALLINT, 
	manu_code CHAR(3), 
	stock_num SMALLINT
);

CREATE TRIGGER validarPermiso_trg
ON items 
AFTER INSERT 
AS 
BEGIN 
	DECLARE @customer_num SMALLINT, 
			@manu_code CHAR(3), 
			@stock_num SMALLINT, 
			@order_num INT

	-- Declaro cursor 
	DECLARE permisos_cursor CURSOR FOR 
		SELECT 
			i.order_num, 
			i.manu_code, 
			i.stock_num 
		FROM 
			inserted i; 

	-- Abro cursor 
	OPEN permisos_cursor
	FETCH FROM permisos_cursor INTO @order_num, @manu_code, @stock_num; 

	-- Logica de cursor
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		-- Pongo valor a la variable customer_num
		BEGIN
			SELECT 
				@customer_num = o.customer_num
			FROM	
				orders o
			WHERE 
				o.order_num = @order_num
		END

		-- Valido si no existe el permiso 
		IF NOT EXISTS (
			SELECT 1 
			FROM PermisosxProducto pxp
			WHERE 
				pxp.customer_num = @customer_num AND 
				pxp.manu_code = @manu_code AND 
				pxp.stock_num = @stock_num
		)
		BEGIN 
			CLOSE permiso_cursor;
			DEALLOCATE permiso_cursor;
			ROLLBACK TRANSACTION;
			THROW 50001, 'No tiene permisos', 1;
			RETURN;
		END
	END 

	-- Cierro cursor 
	CLOSE permiso_cursor;
	DEALLOCATE permiso_cursor;
END; 