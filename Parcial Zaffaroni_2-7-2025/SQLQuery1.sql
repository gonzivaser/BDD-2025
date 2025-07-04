/*
	3. Query
*/

SELECT 
    c.customer_num, 
    c.lname, 
    i.manu_code, 
    i.stock_num, 
    SUM(i.quantity) AS cantidad_comprada
FROM 
    customer c 
    JOIN orders o ON c.customer_num = o.customer_num
    JOIN items i ON o.order_num = i.order_num
WHERE 
    i.manu_code IN ('HSK', 'NRG') AND 
    c.customer_num IN (
        SELECT 
            o1.customer_num 
        FROM 
            orders o1 
            JOIN items i1 ON o1.order_num = i1.order_num
        WHERE 
            i1.manu_code IN ('HSK', 'NRG')
        GROUP BY 
            o1.customer_num
        HAVING 
            COUNT(DISTINCT i1.manu_code) = 2
    )
GROUP BY 
    c.customer_num, c.lname, i.manu_code, i.stock_num
ORDER BY 
    c.customer_num, SUM(i.quantity) DESC;


/*
	4. Procedure 
*/

CREATE PROCEDURE registrarProductoPR 
(@stock_num SMALLINT, @manu_code CHAR(3), @unit_price DECIMAL, @unit_code SMALLINT, @cat_descr TEXT, @cat_picture VARCHAR(255), @cat_advert VARCHAR(255))
AS
BEGIN 
	BEGIN TRY
		BEGIN TRANSACTION
			IF EXISTS (SELECT 1 FROM products WHERE stock_num = @stock_num AND manu_code = @manu_code)
				BEGIN 
					UPDATE products 
					SET 
						unit_price = @unit_price,
						unit_code = @unit_code
					WHERE 
						stock_num = @stock_num AND manu_code = @manu_code;
				END 

			ELSE 
				BEGIN 
					INSERT INTO products (stock_num, manu_code, unit_price, unit_code)
					VALUES (@stock_num, @manu_code, @unit_price, @unit_code); 
				END 

			DECLARE @nuevo_catalog_num SMALLINT; 
			SELECT 
				@nuevo_catalog_num = ISNULL(MAX(catalog_num), 0) + 1
			FROM 
				catalog

			INSERT INTO catalog(catalog_num, stock_num, manu_code, cat_descr, cat_picture, cat_advert)
			VALUES (@nuevo_catalog_num, @stock_num, @manu_code, @cat_descr, @cat_picture, @cat_advert);

		COMMIT TRANSACTION
	END TRY 

	BEGIN CATCH 
		ROLLBACK TRANSACTION; 
		DECLARE @mensajeDeError NVARCHAR(4000);
        SET @mensajeDeError = ERROR_MESSAGE();
		THROW 50000, @mensajeDeError, 1;  
	END CATCH 

END; 


/*
	5. Trigger
*/

SELECT * INTO Clientes_BK FROM customer WHERE 1 = 0
SELECT * INTO Ordenes_BK FROM orders WHERE 1 = 0

CREATE TRIGGER TRG_insertOrdenes
ON Ordenes_BK
INSTEAD OF INSERT
AS
BEGIN
	 IF EXISTS (
            SELECT 1
            FROM inserted i
            LEFT JOIN Clientes_BK cBK ON i.customer_num = cBK.customer_num
            WHERE cBK.customer_num IS NULL
      )
	  BEGIN 
		 THROW 50001, 'El cliente no existe en C_BK.', 1;
	  END

	  ELSE 
	  BEGIN 
		INSERT INTO Ordenes_BK(order_num, order_date, customer_num, ship_instruct, backlog, po_num, ship_date, ship_weight, ship_charge, paid_date) 
		SELECT 
			order_num, order_date, customer_num, ship_instruct, backlog, po_num, ship_date, ship_weight, ship_charge, paid_date
		FROM 
			inserted; 
	  END
END;

CREATE TRIGGER TRG_updateOrdenes
ON Ordenes_BK
INSTEAD OF UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        LEFT JOIN Clientes_BK cBK ON i.customer_num = cBK.customer_num
        WHERE cBK.customer_num IS NULL
    )
    BEGIN
        THROW 50001, 'El cliente no existe en C_BK.', 1;
    END
    
	ELSE
    BEGIN
        UPDATE oBK
        SET 
            oBK.order_date = i.order_date,
            oBK.customer_num = i.customer_num,
            oBK.ship_instruct = i.ship_instruct,
            oBK.backlog = i.backlog,
            oBK.po_num = i.po_num,
            oBK.ship_date = i.ship_date,
            oBK.ship_weight = i.ship_weight,
            oBK.ship_charge = i.ship_charge,
            oBK.paid_date = i.paid_date
        FROM 
            Ordenes_BK oBK
        JOIN 
            inserted i ON oBK.order_num = i.order_num;
    END
END;

CREATE TRIGGER TRG_deleteClientes
ON Clientes_BK 
INSTEAD OF DELETE 
AS 
BEGIN 
	IF EXISTS (
            SELECT 1
            FROM 
			deleted d
			JOIN Ordenes_BK oBK ON d.customer_num = oBK.customer_num
	)
	BEGIN
		THROW 50001, 'El cliente tiene ordenes asociadas.', 1;
	END

	BEGIN;
		DELETE FROM Clientes_BK
		WHERE customer_num IN (SELECT customer_num FROM deleted);
	END
END; 

CREATE TRIGGER TRG_insertClientes
ON Clientes_BK
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        LEFT JOIN orders o ON i.customer_num = o.customer_num
        WHERE o.customer_num IS NULL
    )
    BEGIN
        THROW 50002, 'El cliente no tiene órdenes asociadas.', 1;
    END

    INSERT INTO Clientes_BK (customer_num, fname, lname, company, address1, address2, city, state, zipcode, phone, customer_num_referedBy, status)
    SELECT 
		customer_num, fname, lname, company, address1, address2, city, state, zipcode, phone, customer_num_referedBy, status
    FROM 
		inserted;
END;





