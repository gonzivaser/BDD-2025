/*
	Ejercicio 1: 
	Se pide: Crear un trigger que valide que ante un insert de una o más filas en la tabla
	ítems, realice la siguiente validación:
		? Si la orden de compra a la que pertenecen los ítems ingresados corresponde a
		clientes del estado de California, se deberá validar que estas órdenes puedan tener
		como máximo 5 registros en la tabla ítem.
		? Si se insertan más ítems de los definidos, el resto de los ítems se deberán insertar
		en la tabla items_error la cual contiene la misma estructura que la tabla ítems más
		un atributo fecha que deberá contener la fecha del día en que se trató de insertar.
	Ej. Si la Orden de Compra tiene 3 items y se realiza un insert masivo de 3 ítems más, el
	trigger deberá insertar los 2 primeros en la tabla ítems y el restante en la tabla ítems_error.
	Supuesto: En el caso de un insert masivo los items son de la misma orden.
*/
SELECT * FROM items
CREATE TABLE [items_error](
	[item_num] [smallint] NOT NULL,
	[order_num] [smallint] NOT NULL,
	[stock_num] [smallint] NOT NULL,
	[manu_code] [char](3) NOT NULL,
	[quantity] [smallint] NULL DEFAULT ((1)),
	[unit_price] [decimal](8, 2) NULL,
	[fecha] [datetime] NULL
);

CREATE TRIGGER 
