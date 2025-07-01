/*
	1. Explique el objeto Vista, sus caracteristicas y para que usarlo y su relación con las funcionalidades
	de seguridad e integridad. Compárelo con el objeto snapshot.
	
	Una vista es un objeto virtual de base de datos que representa el resultado de una consulta SELECT. No almacena datos, 
	sino que muestra información derivada de una o más tablas.
	Con la seguridad, podes ocultar columnas y mostrar solo lo necesario para el usario. 
	Con la integridad, con WITH CHECK OPTION, se garantiza que los cambios hechos a traves de la vista respeten sus condiciones.

	Comparacion con snapshot: 
	View: Virtual, siempre actualizada, ligera, sin uso de espacio adicional y se usa para seguridad, simplicidad
	Snapshot: Es fisica (guarda datos), se debe refrescar manualmente, consume espacio de almcanamiento y se usa para mejorar performance
*/

/*
	2.  Explique la diferencia entre integridad y consistencia. Describa dos objetos o conceptos asociados a cada una.
	La integridad se refiere a garantizar que los datos sean correctos, válidos y estén completos. 
	Impide que se ingresen datos erróneos o inconsistentes, mientras que la Consistencia, Se refiere a mantener la base de datos 
	en un estado válido tras cada transacción, asegurando que las reglas de negocio y las restricciones se respeten.

	Objetos relacionados con integridad: 
	Constraints: Restricciones como PRIMARY KEY, FOREIGN KEY, y CHECK, aseguran la validez de los datos 
	Triggers: Controlan que las reglas de integridad se cumplan al realizar cambio en los datos

	Objetos relacionados con la consistencia: 
	Transacciones:  Aseguran que un conjunto de operaciones se ejecute completamente o se deshaga, 
					manteniendo la base de datos en un estado válido.
	Logs Transaccionales: Permiten la recuperación de datos en caso de fallo, asegurando que la base de datos no 
							quede en un estado inconsistente.
*/

/*
	3. Query
	Realizar un query que muestre los Referentes que hayan comprado mas que la suma de todos sus
	referidos. Mostrar Nro cliente, Apellido, nombre, Monto total comprado y monto total comprado de todos
	sus referidos. Mostrar la información ordenada por nro de cliente referente. 
	No se puede utilizar subqueries en la  cláusula SELECT del query, ni funciones, ni tablas temporales.
*/

SELECT 
	referente.customer_num, 
	referente.lname, 
	referente.fname, 
	SUM(i.quantity * i.unit_price) AS monto_total_referente,
	SUM(i_referidos.quantity * i_referidos.unit_price) AS monto_total_referidos
FROM 
	customer referente
	JOIN orders o ON referente.customer_num = o.customer_num
	JOIN items i ON o.order_num = i.order_num
	LEFT JOIN customer referidos ON referente.customer_num_referedBy = referidos.customer_num
	LEFT JOIN orders o_ref ON referidos.customer_num = o_ref.customer_num
	LEFT JOIN items i_referidos ON o_ref.order_num = i_referidos.order_num
GROUP BY
	referente.customer_num, 
	referente.lname, 
	referente.fname
HAVING 
	SUM(i.quantity * i.unit_price) > SUM(i_referidos.quantity * i_referidos.unit_price)
ORDER BY 
	referente.customer_num

/*
	4. Trigger
*/

CREATE VIEW OrdenesItems AS
SELECT 
	o.order_num, 
	o.order_date, 
	o.customer_num, 
	o.paid_date, 
	i.item_num, 
	i.stock_num, 
	i.manu_code
FROM 
	orders o 
	join items i ON o.order_num = i.order_num


CREATE TRIGGER TR_ordenes
ON OrdenesItems
INSTEAD OF INSERT 
AS
BEGIN 
	
	-- Declaro Variables
	DECLARE @order_num SMALLINT, 
			@customer_num SMALLINT, 
			@stock_num SMALLINT, 
			@manu_code CHAR(3), 
			@provincia CHAR(2), 
			@order_date DATETIME, 
			@paid_date DATETIME, 
			@item_num SMALLINT; 

	-- Declaro Cursor 
	DECLARE ordenes_cursor CURSOR FOR 
	SELECT 
		i.order_num, 
		i.customer_num, 
		i.stock_num, 
		i.manu_code
	FROM 
		inserted i 
	
	-- Abro el Cursor
	OPEN ordenes_cursor; 
	FETCH ordenes_cursor INTO @order_num, @customer_num, @stock_num, @manu_code; 

	-- Logica de Cursor
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		BEGIN TRY 
			BEGIN TRANSACTION
			-- Verifico que los datos sean de una misma orden y un mismo cliente 
			IF NOT EXISTS (
				SELECT 1 
				FROM inserted i 
				WHERE i.order_num <> @order_num AND i.customer_num <> @customer_num
			)			

			-- Verifico que la orden no tenga Productos de fabricantes de mas de 1 provincia 
			SELECT 
				@provincia = m.state
			FROM 
				products p 
				JOIN manufact m ON p.manu_code = m.manu_code
			WHERE 
				p.manu_code = @manu_code AND p.stock_num = @stock_num; 

			IF NOT EXISTS (
				SELECT 1 
				FROM 
					inserted i 
					JOIN products p ON i.manu_code = p.manu_code AND i.stock_num = p.stock_num
					JOIN manufact m ON p.manu_code = m.manu_code
				WHERE 
					i.order_num = @order_num
				GROUP BY 
					m.state
				HAVING 
					COUNT(DISTINCT m.state) > 1
			)

			-- Doy valor a las variables 
			SELECT 
				@order_date = o.order_date, 
				@paid_date = o.paid_date, 
				@item_num = i.item_num
			FROM 
				orders o 
				JOIN items i ON o.order_num = i.order_num
			WHERE 
				o.order_num = @order_num AND 
				o.customer_num = @customer_num AND 
				i.manu_code = @manu_code AND 
				i.stock_num = @stock_num; 

			-- INSERT EN LA VIEW
			INSERT INTO OrdenesItems(order_num, order_date, customer_num, paid_date, item_num, stock_num, manu_code)
			VALUES (@order_num, @order_date, @customer_num, @paid_date, @item_num, @stock_num, @manu_code); 


			-- Muevo Cursor 
			FETCH ordenes_cursor INTO @order_num, @customer_num, @stock_num, @manu_code; 
			COMMIT TRANSACTION

			CLOSE ordenes_cursor; 
			DEALLOCATE ordenes_cursor;
		END TRY

		BEGIN CATCH 
			-- Si hay error, cierro y desalojo cursor
			CLOSE ordenes_cursor; 
			DEALLOCATE ordenes_cursor;

			ROLLBACK TRANSACTION
			DECLARE @errorDescription VARCHAR(100)
			SELECT @errorDescription = 'Error al ingresar datos';
			THROW 50001, @errorDescription, 1; 
		END CATCH
	END 
END; 


/*
	5. Procedure
*/
-- a)
CREATE TABLE CuentaCorriente (
	id INT IDENTITY(1,1) PRIMARY KEY, 
	fechaMovimiento DATETIME, 
	customer_num SMALLINT,
	order_num SMALLINT,
	importe DECIMAL(12,2), 
	FOREIGN KEY (customer_num) REFERENCES Customer(customer_num),
    FOREIGN KEY (order_num) REFERENCES Orders(order_num)
);

CREATE TABLE ErroresCtaCte (
	order_num SMALLINT, 
	mensajeError VARCHAR(100)
);

-- b) 
CREATE PROCEDURE SP_cargarTablaCC
AS
BEGIN 
	-- Declaro Variables 
	DECLARE @orden_num SMALLINT, 
			@customer_num SMALLINT, 
			@fechaMovimiento DATETIME, 
			@importe DECIMAL(12,2), 
			@importeFinal DECIMAL(12,2); 

	-- Declaro Cursor 
	DECLARE cuentaCorriente_cursor CURSOR FOR 
		SELECT 
			o.order_num, 
			o.customer_num, 
			o.order_date, 
			SUM(i.quantity * i.unit_price)
		FROM 
			orders o 
			JOIN items i ON o.order_num = i.order_num
		GROUP BY 
			o.order_num, 
			o.customer_num, 
			o.order_date;

	-- Abro cursor 
	OPEN cuentaCorriente_cursor; 
	FETCH cuentaCorriente_cursor INTO @orden_num, @customer_num, @fechaMovimiento, @importe; 

	-- Logica de cursor 
	WHILE @@FETCH_STATUS = 0
	BEGIN 
		BEGIN TRY
			BEGIN TRANSACTION 
				-- Verifico si es orden pagada o no
				IF EXISTS(SELECT 1 FROM orders WHERE order_num = @orden_num AND paid_date IS NOT NULL)
				BEGIN 
					SET @importeFinal = @importe * (-1); 
				END
				ELSE 
				BEGIN
					SET @importeFinal = @importe
				END

				-- Inserto en la tabla 
				INSERT INTO CuentaCorriente(fechaMovimiento, customer_num, order_num, importe)
				VALUES (@fechaMovimiento, @customer_num, @orden_num, @importeFinal); 

			COMMIT TRANSACTION 
		END TRY

		BEGIN CATCH 
			ROLLBACK TRANSACTION
			DECLARE @errorDescription VARCHAR(100); 
			SET @errorDescription = 'Error al insertar datos en la tabla de Cuenta Corriente'

			-- Inserto en la tabla de errores
			INSERT INTO ErroresCtaCte(order_num, mensajeError)
			VALUES (@orden_num, @errorDescription); 
		END CATCH

		FETCH cuentaCorriente_cursor INTO @orden_num, @customer_num, @fechaMovimiento, @importe; 
	END

	CLOSE cuentaCorriente_cursor; 
	DEALLOCATE cuentaCorriente_cursor; 
END; 



