/*Ejercicio 1: 
Dada la tabla Products de la base de datos stores7 se requiere crear una tabla
Products_historia_precios y crear un trigger que registre los cambios de precios que se hayan
producido en la tabla Products.
Tabla Products_historia_precios
 Stock_historia_Id Identity (PK)
 Stock_num
 Manu_code
 fechaHora (grabar fecha y hora del evento)
 usuario (grabar usuario que realiza el cambio de precios)
 unit_price_old
 unit_price_new
 estado char default ‘A’ check (estado IN (‘A’,’I’)
*/

-- CREO TABLA Product_Historia_precios
CREATE TABLE Product_historia_precios (
	stock_historia_id int IDENTITY(1,1) PRIMARY KEY,
	stock_num smallint,
	manu_code char(3),
	fechaHora datetime,
	usuario varchar(20),
	unit_price_old decimal(6,2),
	unit_price_new decimal(6,2),
	estado char DEFAULT 'A' CHECK(estado IN('A','I')),
);

-- CREO TRIGGER PARA CUALQUIER CAMBIO DE LA TABLA PRODUCTOS 
CREATE TRIGGER cambio_precios_tr ON products 
AFTER UPDATE AS
BEGIN 
	DECLARE @unit_price_old decimal(6,2)
	DECLARE @unit_price_new decimal(6,2)
	DECLARE @stock_num smallint
	DECLARE @manu_code char(3)

	-- DECLARO CURSOR PARA MOVERME EN LA TABLA PRODUCTOS
	DECLARE precios_stock_cursor CURSOR FOR 
	SELECT 
		i.stock_num, 
		i.manu_code, 
		i.unit_price, 
		d.unit_price
	FROM 
		inserted i 
	JOIN deleted d ON (i.stock_num = d.stock_num AND i.manu_code = d.manu_code)
	WHERE 
		i.unit_price != d.unit_price;

	-- ABRO CURSOR 
	OPEN precios_stock_cursor 
	FETCH NEXT FROM precios_stock_cursor INTO @stock_num, @manu_code, @unit_price_new, @unit_price_old

	-- RECORRO CURSOR 
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		INSERT INTO Product_historia_precios(stock_num, manu_code, unit_price_new, unit_price_old, fechaHora, usuario)
		VALUES (@stock_num, @manu_code, @unit_price_new, @unit_price_old, GETDATE(), SYSTEM_USER)

	-- AVANZO CURSOR 
	FETCH NEXT FROM precios_stock_cursor INTO @stock_num, @manu_code, @unit_price_new, @unit_price_old
	END 

	-- CIERRO CURSOR 
	CLOSE precios_stock_cursor
	DEALLOCATE precios_stock_cursor
END;


/*Ejercicio 2: Crear un trigger sobre la tabla Products_historia_precios que ante un delete sobre la misma
	realice en su lugar un update del campo estado de ‘A’ a ‘I’ (inactivo).*/
CREATE TRIGGER trg_delete_historia ON Product_historia_precios
INSTEAD OF DELETE AS 
BEGIN 
	UPDATE php
	SET 
		estado = 'I'
	FROM 
		Product_historia_precios php
	INNER JOIN deleted d ON php.stock_historia_id =	d.stock_historia_id
	WHERE	
		php.estado = 'A'
END; 


-- 1. Insertar prueba
INSERT INTO Product_historia_precios
    (stock_num, manu_code, fechaHora, usuario, unit_price_old, unit_price_new)
VALUES
    (1001, 'ABC', GETDATE(), SYSTEM_USER, 100.00, 150.00);

-- 2. Buscar el ID recién insertado (supongamos que es 4)
SELECT * FROM Product_historia_precios ORDER BY stock_historia_id DESC;

-- 3. Intentar borrar (se actualizará a estado = 'I')
DELETE FROM Product_historia_precios
WHERE stock_historia_id = 6;

-- 4. Verificar que el estado cambió a 'I'
SELECT * FROM Product_historia_precios


/*Ejercicio 3: Validar que sólo se puedan hacer inserts en la tabla Products en un horario entre las 8:00 AM y
8:00 PM. En caso contrario enviar un error por pantalla.*/
CREATE TRIGGER trg_insert_stock ON products 
INSTEAD OF INSERT 
AS
BEGIN 
	IF(DATEPART(HOUR, GETDATE()) BETWEEN 8 AND 20)
		BEGIN 
			RAISERROR('Maestro que hace a esta hora trabajando?', 16, 1)
			END
END; 

/*Ejercicio 4: Crear un trigger que ante un borrado sobre la tabla ORDERS realice un borrado en cascada
sobre la tabla ITEMS, validando que sólo se borre 1 orden de compra.
Si detecta que están queriendo borrar más de una orden de compra, informará un error y
abortará la operación.*/
CREATE TRIGGER trg_delete_ordenes ON orders 
INSTEAD OF DELETE 
AS 
BEGIN 
	DECLARE @num_ordenes INT; 

	SELECT @num_ordenes = COUNT(*) FROM deleted; 

	IF @num_ordenes > 1 
		BEGIN 
			RAISERROR('Solo se puede borrar una orden.',16,1); 
			ROLLBACK TRANSACTION; 
			RETURN;
		END
	
	ELSE 
		BEGIN 
			DELETE FROM items
			WHERE
				order_num IN (SELECT order_num FROM deleted); 
			DELETE FROM orders
			WHERE 
				order_num IN (SELECT order_num FROM deleted);
		END
END;


/*Ejercicio 5: Crear un trigger de insert sobre la tabla ítems que al detectar que el código de fabricante
(manu_code) del producto a comprar no existe en la tabla manufact, inserte una fila en dicha
tabla con el manu_code ingresado, en el campo manu_name la descripción ‘Manu Orden 999’
donde 999 corresponde al nro. de la orden de compra a la que pertenece el ítem y en el campo
lead_time el valor 1.*/