/* 
	1) 3. Query
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

/* 
	2) 4. Stored Procedure
	Crear un procedimiento BorrarProd que en base a una tabla ProductosDeprecados que
	contiene filas con Productos a borrar realice la eliminación de los mismos de la tabla
	Products. El procedimiento deberá guardar en una tabla de auditoria AuditProd (stock_num,
	manu_code, Mensaje) el producto y un mensaje que podrá ser: ‘Borrado’, ‘Producto con ventas’
	o cualquier mensaje de error que se produjera. Crear las tablas ProductosDeprecados y
	AuditProd.
	Deberá manejar una transacción por registro. Ante un error deshacer lo realizado y seguir
	procesando los demás registros. Asimismo, deberá manejar excepciones ante cualquier error
	que ocurra.
*/

CREATE TABLE AuditProd (
	stock_num SMALLINT, 
	manu_code CHAR(3), 
	Mensaje VARCHAR(100)
); 

SELECT * INTO ProductosDeprecados FROM products WHERE 1 = 0;

-- Creo el Procedure
CREATE PROCEDURE BorrarProd
AS
BEGIN 
	-- Declaro variables
	DECLARE @prodBorrado_Stock_Num SMALLINT; 
	DECLARE @prodBorrado_Manu_Code CHAR(3); 
	DECLARE @prodBorrado_Mensaje VARCHAR(100);

	-- Creo Cursor 
	DECLARE prodBorrados_cursor CURSOR FOR 
		SELECT stock_num, manu_code FROM ProductosDeprecados; 

	-- Abro Cursor 
	OPEN prodBorrados_cursor; 
	FETCH prodBorrados_cursor INTO @prodBorrado_Stock_Num, @prodBorrado_Manu_Code; 

	-- Logica en el cursor 
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		BEGIN TRY
			BEGIN TRANSACTION
				-- Si tuvo ventas --> Seteo al mensaje a "Producto con ventas"
				IF EXISTS(SELECT 1 FROM items WHERE stock_num = @prodBorrado_Stock_Num AND manu_code = @prodBorrado_Manu_Code)
					BEGIN
						SET @prodBorrado_Mensaje = 'Producto con ventas'; 
					END
				
				-- Si no tuvo ventas --> 
				ELSE 
				BEGIN 
					SET @prodBorrado_Mensaje = 'Borrado'; 

					DELETE FROM products 
					WHERE stock_num = @prodBorrado_Stock_Num AND manu_code = @prodBorrado_Manu_Code
				END

				-- Ahora lo guardo en la tabla de AuditProd
				BEGIN
					INSERT INTO AuditProd(stock_num, manu_code, Mensaje)
					VALUES (@prodBorrado_Stock_Num, @prodBorrado_Manu_Code, @prodBorrado_Mensaje);
				END

			COMMIT TRANSACTION; 
		END TRY

		BEGIN CATCH	
			ROLLBACK TRANSACTION; 
				-- Si hubo un error, lo inserto en la tabla de AudiProd con el error 
				INSERT INTO AuditProd (stock_num, manu_code, Mensaje)
				VALUES (@prodBorrado_Stock_Num, @prodBorrado_Manu_Code, ERROR_MESSAGE());
		END CATCH; 

		-- Avanzo cursor 
		FETCH prodBorrados_cursor INTO @prodBorrado_Stock_Num, @prodBorrado_Manu_Code; 

	END

	-- Cierro cursor 
	CLOSE prodBorrados_cursor; 
	DEALLOCATE prodBorrados_cursor; 
END; 

/*CASOS DE PRUEBA*/
-- VEO LOS MANU CODES QUE ESTAN EN LA TABLA PRODCUTOS
SELECT * FROM products

-- VEO LOS MANU CODE QUE ESTAN EN LA TABLA ITEMS PARA INSERTAR ESE A PRODUCTOS DEPRECADOS
SELECT * FROM items

-- LOS INSERTO
INSERT INTO ProductosDeprecados (stock_num, manu_code)
VALUES (1, 'HRO');

-- EJECUTO EL PROCEDIMIENTO Y VEO SI FUNCIONO 
EXEC BorrarProd;
SELECT * FROM AuditProd;



/*
	3) 5. Trigger
	Crear un trigger que ante un cambio de precios en un producto inserte un nuevo registro con el precio anterior	
	(no el nuevo) en la tabla PRECIOS_HIST.
	La estructura de la tabla PRECIOS_HIST  es (stock_num, manu_code, fechaDesde, fechaHasta, precio_unit).  
	La fecha desde del nuevo registro será la fecha hasta del último cambio de precios de ese producto y su fecha 
	hasta será la fecha del dia. SI no tuviese un registro de precio anterior ingrese como fecha desde ‘2000-01-01’.
	Nota: Las actualizaciones de precios pueden ser masivas.
*/

CREATE TABLE Precios_Hist (
	stock_num SMALLINT, 
	manu_code CHAR(3), 
	fechaDesde DATE, 
	fechaHasta DATE, 
	precio_unit DECIMAL(10, 2)
);

CREATE TRIGGER actualizarPreciosDeProducto_trg
ON products 
AFTER UPDATE 
AS 
BEGIN 
	IF UPDATE(unit_price) 
	BEGIN 
		DECLARE @stock_num SMALLINT; 
		DECLARE @manu_code CHAR(3); 
		DECLARE @fechaDesde DATE; 
		DECLARE @fechaHasta DATE; 
		DECLARE @last_price DECIMAL(10,2); 

		-- Creo cursor 
		DECLARE prodPrecioActualizados_cursor CURSOR FOR 
			SELECT 
				i.stock_num, 
				i.manu_code, 
				d.unit_price
			FROM
				inserted i 
				JOIN deleted d ON i.stock_num = d.stock_num
			WHERE 
				i.unit_price <> d.unit_price; 

		-- Abro cursor 
		OPEN prodPrecioActualizado_cursor; 
		FETCH prodPrecioActualizado_cursor INTO @stock_num, @manu_code, @last_price; 

		-- Logica en el cursor 
		WHILE @@FETCH_STATUS = 0
		BEGIN 
			-- Pongo valor a atributo fechaDesde y fechaHasta
			BEGIN
				SELECT
					@fechaHasta = CAST(GETDATE() AS DATE),
					@fechaDesde = ISNULL(
						(SELECT MAX(ph.fechaHasta)FROM Precios_Hist ph WHERE ph.stock_num = @stock_num AND ph.manu_code = @manu_code), 
						'2000-01-01')
				FROM 
					Precios_Hist
				WHERE 
					stock_num = @stock_num AND manu_code = @manu_code
			END

			-- Inserto en la tabla de Precios_Hist
			BEGIN 
				INSERT INTO Precios_Hist(stock_num, manu_code, fechaDesde, fechaHasta, precio_unit)
				VALUES (@stock_num, @manu_code, @fechaDesde, @fechaHasta, @last_price); 
			END 

			-- Avanzo cursor 
			FETCH prodPrecioActualizado_cursor INTO @stock_num, @manu_code, @last_price;
		END 

		-- Cierro cursor
		CLOSE prodPrecioActualizado_cursor;
		DEALLOCATE prodPrecioActualizado_cursor;

	END
END;










