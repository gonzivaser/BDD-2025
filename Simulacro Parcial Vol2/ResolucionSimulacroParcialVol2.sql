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

CREATE TABLE ProductosDeprecados (
	stock_num SMALLINT, 
	manu_code CHAR(3)
);

-- Creo el Procedure
CREATE PROCEDURE BorrarProd
AS
BEGIN 
	-- Declaro variables
	DECLARE @stock_num SMALLINT; 
	DECLARE @manu_code CHAR(3); 
	DECLARE @mensaje VARCHAR(100);

	-- Declaro Cursor
	DECLARE productos_cursor CURSOR FOR 
		SELECT stock_num, manu_code FROM ProductosDeprecados; 

	-- Abro cursor 
	OPEN productos_cursor; 
	FETCH NEXT FROM productos_cursor INTO @stock_num, @manu_code;

	WHILE @@FETCH_STATUS = 0
	BEGIN 
		BEGIN TRY 
			BEGIN TRANSACTION; 

				-- Verifico si producto tuvo ventas 
				IF EXISTS (
					SELECT 1 FROM items i WHERE @stock_num = i.stock_num AND @manu_code = i.manu_code
				)

				-- Seteo mensaje a 'Producto con Ventas'
				BEGIN 
					SET @mensaje = 'Producto con Ventas'
				END

				-- Si el producto no tuvo ventas, seteo mensaje a 'Borrado' y lo borro de la tabla de productos
				ELSE 
				BEGIN 
					SET @mensaje = 'Borrado';
					DELETE FROM products 
					WHERE 
						@stock_num = stock_num AND @manu_code = manu_code
				END

				-- Guardo en la tabla de AuditProd
				BEGIN
					INSERT INTO AuditProd(stock_num, manu_code, Mensaje)
					VALUES (@stock_num, @manu_code, @mensaje); 
				END

			COMMIT TRANSACTION;
		END TRY

		BEGIN CATCH
			ROLLBACK TRANSACTION; 
				SET @mensaje = ERROR_MESSAGE(); 

				-- Guardo en la tabla de AuditProd
				BEGIN
					INSERT INTO AuditProd(stock_num, manu_code, Mensaje)
					VALUES (@stock_num, @manu_code, @mensaje); 
				END
		END CATCH; 

		-- Avanzo cursor 
		FETCH NEXT FROM productos_cursor INTO @stock_num, @manu_code; 
	
	END

	CLOSE productos_cursor; 
	DEALLOCATE productos_cursor; 
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

DROP TABLE PRECIOS_HIST;

CREATE TABLE Precios_Hist (
	stock_num SMALLINT, 
	manu_code CHAR(3), 
	fechaDesde DATE, 
	fechaHasta DATE, 
	precio_unit DECIMAL(10, 2)
);

CREATE TRIGGER trg_actualizarPrecioVol2
ON products 
AFTER UPDATE 
AS
BEGIN 
	INSERT INTO Precios_Hist(stock_num, manu_code, fechaDesde, fechaHasta, precio_unit)
	SELECT 
		d.stock_num, 
		d.manu_code, 
		ISNULL(
			(
				SELECT MAX(ph.fechaHasta)
				FROM Precios_Hist ph
				WHERE ph.stock_num = d.stock_num AND ph.manu_code = d.manu_code
			),'2000-01-01'
		) AS fechaDesde, 
		CAST(GETDATE() AS DATE) AS fechaHasta, 
		d.unit_price
	FROM 
		deleted d
		JOIN inserted i ON d.stock_num = i.stock_num AND d.manu_code = i.manu_code
	WHERE 
		d.unit_price <> i.unit_price
END;


