/*Ejercicio 1: 
Escribir una sentencia SELECT que devuelva el número de orden, fecha de orden y el nombre del
día de la semana de la orden de todas las órdenes que no han sido pagadas.
Si el cliente pertenece al estado de California el día de la semana debe devolverse en inglés, caso
contrario en español. Cree una función para resolver este tema.
Nota: SET @DIA = datepart(weekday,@fecha)
Devuelve en la variable @DIA el nro. de día de la semana , comenzando con 1 Domingo hasta 7
Sábado.*/

-- CREO LA FUNCION 
CREATE FUNCTION Fx_DIA_SEMANA(@fecha DATETIME, @idioma VARCHAR(20)) RETURNS VARCHAR(20)
AS
BEGIN 
DECLARE @dia INT
DECLARE @retorno VARCHAR(20)

SET @DIA = DATEPART(weekday, @fecha)

IF @idioma = 'espaniol' 
	BEGIN 
	SET @retorno = 
		CASE 
			WHEN @dia = 1 THEN 'Domingo'
			WHEN @dia = 2 THEN 'Lunes'
			WHEN @dia = 3 THEN 'Martes'
			WHEN @dia = 4 THEN 'Miercoles'
			WHEN @dia = 5 THEN 'Jueves'
			WHEN @dia = 6 THEN 'Viernes'	
			ELSE 'Sabado'
			END 
	END 
ELSE 
	BEGIN 
	SET @retorno = 
		CASE 
			WHEN @dia = 1 THEN 'Sunday'
			WHEN @dia = 2 THEN 'Monday'
			WHEN @dia = 3 THEN 'Tuesday'
			WHEN @dia = 4 THEN 'Wednesday'
			WHEN @dia = 5 THEN 'Thursday'
			WHEN @dia = 6 THEN 'Friday'	
			ELSE 'Sunday'
			END 
	END 
RETURN @retorno
END


-- ESCRIBO LA SENTENCIA SELECT 
SELECT 
	order_num, 
	order_date, 
	CASE
		WHEN state = 'CA' THEN dbo.Fx_DIA_SEMANA(order_date, 'ingles')
		WHEN state != 'CA' or state IS NULL THEN dbo.Fx_DIA_SEMANA(order_date, 'espaniol')
	END 
FROM 
	orders o, 
	customer c
WHERE 
	o.customer_num = c.customer_num AND 
	paid_date IS NULL
