/*
	Ejercicio 3. Query
	Por cada estado (state) seleccionar los dos clientes que mayores montos compraron. 
	Se deberá mostrar el código del estado, nro de cliente, nombre y apellido del cliente y monto total comprado.
	Mostrar la información ordenada por provincia y por monto comprado en forma descendente.
	Notas: No se puede usar Store procedures, ni funciones de usuarios, ni tablas temporales.
*/

SELECT 
    c.state, 
    c.customer_num, 
    CONCAT(c.fname, ' ', c.lname) AS nombre_apellido, 
    SUM(i.quantity * i.unit_price) AS monto_total_comprado
FROM 
    customer c
    JOIN orders o ON c.customer_num = o.customer_num
    JOIN items i ON o.order_num = i.order_num
GROUP BY 
    c.state, 
    c.customer_num, 
    c.fname, 
    c.lname
HAVING 
    (
        SELECT COUNT(*)
        FROM (
            SELECT c2.customer_num, SUM(i2.quantity * i2.unit_price) AS monto
            FROM customer c2 
                JOIN orders o2 ON c2.customer_num = o2.customer_num
                JOIN items i2 ON o2.order_num = i2.order_num
            WHERE c2.state = c.state
            GROUP BY c2.customer_num
            HAVING SUM(i2.quantity * i2.unit_price) > SUM(i.quantity * i.unit_price)
        ) AS mayores
    ) < 2
ORDER BY 
    c.state, 
    monto_total_comprado DESC;

SELECT 
    c.state, 
    c.customer_num, 
    CONCAT(c.fname, ' ', c.lname) AS nombre_apellido, 
    SUM(i.quantity * i.unit_price) AS monto_total_comprado
FROM 
    customer c
    JOIN orders o ON c.customer_num = o.customer_num
    JOIN items i ON o.order_num = i.order_num
WHERE
	c.customer_num IN (
		SELECT TOP 2 c1.customer_num AS customer_num 
		FROM 
			customer c1
			JOIN orders o1 ON c1.customer_num = o1.customer_num
			JOIN items i1 ON o1.order_num = i1.order_num
		WHERE 
			c1.state = c.state
	)
GROUP BY 
	c.customer_num, 
	c.fname, 
	c.lname,
	c.state
ORDER BY
	c.state, 
	SUM(i.quantity * i.unit_price) DESC


/*
	Ejercicio 4. Store Procedure
	Crear un procedimiento BorrarProd que en base a una tabla ProductosDeprecados que contiene filas con Productos a 
	borrar realice la eliminación de los mismos de la tabla Products. El procedimiento deberá guardar en una tabla de 
	auditoria AuditProd (stock_num, manu_code, Mensaje) el producto y un mensaje que podrá ser: ‘Borrado’, ‘Producto con ventas’ o 
	cualquier mensaje de error que se produjera. Crear las tablas ProductosDeprecados y AuditProd.
	Deberá manejar una transacción por registro. Ante un error deshacer lo realizado y seguir procesando los 
	demás registros. Asimismo, deberá manejar excepciones ante cualquier error que ocurra.
*/

CREATE TABLE ProductosDeprecados (
    stock_num SMALLINT,
    manu_code CHAR(3)
);

CREATE TABLE AuditProd (
    stock_num SMALLINT,
    manu_code CHAR(3),
    Mensaje VARCHAR(100)
);

CREATE PROCEDURE BorrarProd 
AS
BEGIN 
	DECLARE @stock_num SMALLINT;
    DECLARE @manu_code CHAR(3);
    DECLARE @mensaje VARCHAR(100);

	DECLARE productos_cursor CURSOR FOR
		SELECT stock_num, manu_code FROM ProductosDeprecados; 

	OPEN productos_cursor; 
	FETCH NEXT FROM productos_cursor INTO @stock_num, @manu_code;

	WHILE @@FETCH_STATUS = 0
	BEGIN 
		BEGIN TRY 
			BEGIN TRANSACTION; 

			-- Verifico si el producto tiene ventas 
			IF EXISTS (
				SELECT *
				FROM items 
				WHERE stock_num = @stock_num AND manu_code = @manu_code
			)
			
			BEGIN 
				SET @mensaje = 'Producto con ventas';
			END

			ELSE 
			BEGIN 
				DELETE FROM products
				WHERE stock_num = @stock_num AND manu_code = @manu_code

				SET @mensaje = 'Producto con ventas';
			END 

			-- Guardo en la tabla de AuditProd 
			INSERT INTO AuditProd (stock_num, manu_code, Mensaje)
			VALUES (@stock_num, @manu_code, @mensaje)

			COMMIT TRANSACTION; 
		END TRY

		BEGIN CATCH 
			ROLLBACK TRANSACTION; 
				SET @mensaje = ERROR_MESSAGE();

				INSERT INTO AuditProd (stock_num, manu_code, Mensaje)
				VALUES (@stock_num, @manu_code, @mensaje);
		END CATCH; 

		-- Avanzo cursor 
		FETCH NEXT FROM productos_cursor INTO @stock_num, @manu_code; 
	END

	CLOSE productos_cursor; 
	DEALLOCATE productos_cursor; 
END; 


/*Casos de Prueba:*/
INSERT INTO products (stock_num, manu_code, unit_price, unit_code)
VALUES (1010, 'ABC', 100.00, 'UNI'); -- Asegurate que 'UNI' existe en `units`

INSERT INTO ProductosDeprecados (stock_num, manu_code)
VALUES (1010, 'ABC');

EXEC BorrarProd;
SELECT * FROM AuditProd;


/*
	Ejercicio 5. Trigger
	Crear un trigger que ante un cambio de precios en un producto inserte un nuevo registro con el precio anterior	
	(no el nuevo) en la tabla PRECIOS_HIST.
	La estructura de la tabla PRECIOS_HIST  es (stock_num, manu_code, fechaDesde, fechaHasta, precio_unit).  
	La fecha desde del nuevo registro será la fecha hasta del último cambio de precios de ese producto y su fecha 
	hasta será la fecha del dia. SI no tuviese un registro de precio anterior ingrese como fecha desde ‘2000-01-01’.
	Nota: Las actualizaciones de precios pueden ser masivas.
*/

CREATE TABLE PRECIOS_HIST (
    stock_num SMALLINT,
    manu_code CHAR(3),
    fechaDesde DATE,
    fechaHasta DATE,
    precio_unit DECIMAL(10, 2)
);

CREATE TRIGGER trg_actualizarPrecio
ON products 
AFTER UPDATE 
AS 
BEGIN 
	INSERT INTO PRECIOS_HIST(stock_num, manu_code, fechaDesde, fechaHasta, precio_unit)
	SELECT 
		d.stock_num, 
		d.manu_code, 
		ISNULL(
			(
				SELECT MAX(ph.fechaHasta)
				FROM PRECIOS_HIST ph
				WHERE ph.stock_num = d.stock_num AND ph.manu_code = d.manu_code), 
				'2000-01-01'
			) AS fecha_desde, 
		CAST(GETDATE() AS DATE) AS fechaHasta, 
		d.unit_price
	FROM 
		deleted d
		JOIN inserted i ON d.stock_num = i.stock_num AND d.manu_code = i.manu_code
	WHERE 
		d.unit_price <> i.unit_price;
END;


	