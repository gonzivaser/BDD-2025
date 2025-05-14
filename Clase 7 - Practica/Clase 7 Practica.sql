-- STORED PROCEDURES
-- EJERCICIO A)
CREATE TABLE CustomerStatistics (
    customer_num INT PRIMARY KEY, 
    ordersqty INT, 
    maxdate DATE, 
    uniqueProducts INT
); 

CREATE PROCEDURE actualizarEstadisticas(@customer_numDES INTEGER, @customer_numHAS INTEGER)
    AS
    BEGIN 

    /*DECLARO CURSOR PARA IR ENTRE LAS TABLAS*/
    DECLARE customer_entre_cursor CURSOR FOR 
        SELECT 
            customer_num
        FROM 
            customer 
        WHERE 
            customer_num BETWEEN @customer_numDES AND @customer_numHAS
    
    /*DECLARO CUSTOMER ENTRE CURSOR*/
    DECLARE @customer_id INTEGER
    OPEN customer_entre_cursor
    FETCH customer_entre_cursor INTO @customer_id

    /*ARRANCO EL BUCLE DEL CURSOR*/
    WHILE (@@FETCH_STATUS = 0)
        BEGIN 
        /*DECLARO VARIABLES A INSERTAR*/
        DECLARE @ordersqty INTEGER
        SET @ordersqty = (
            SELECT 
                COUNT (*)
            FROM 
                orders o
            WHERE
                o.customer_num = @customer_id
        )

        DECLARE @maxDate DATE 
        SET @maxDate = (
            SELECT 
                MAX(o.order_date)
            FROM 
                orders o 
            WHERE 
                o.customer_num = @customer_num
        )

        DECLARE @uniqueProducts INTEGER 
        SET @uniqueProducts = (
            SELECT 
                COUNT(DISTINCT p.stock_num) 
            FROM  
                products p 
	        JOIN 
                items i ON i.stock_num = p.stock_num
	        JOIN 
                orders o ON i.order_num = o.order_num
	        WHERE 
                o.customer_num = @customer_id
        )


        /*AHORA ME FIJO SI EXISTE, ACTUALIZO, Y SINO EXISTE, INSERTO*/
        IF EXISTS (
            SELECT 
                customer_num
            FROM 
                CustomerStatistics
            WHERE 
                customer_num = @customer_id
        )

        BEGIN 
            UPDATE 
                CustomerStatistics
            SET 
                ordersqty = @ordersqty
                maxDate = @maxDate
                uniqueProducts = @uniqueProducts
            WHERE 
                customer_num = @customer_id
        END 

        ELSE 
            BEGIN 
                INSERT INTO CustomerStatistics (customer_num, ordersqty, maxDate, uniqueProducts)
                VALUES (@customer_id, @ordersqty, @maxDate, @uniqueProducts)
            END 


        /*AVANZO EL CURSOR*/
        FETCH customers_entre_cursor INTO @customer_id
    END

    CLOSE customers_entre_cursor
    DEALLOCATE customers_entre_cursor 
END

    


