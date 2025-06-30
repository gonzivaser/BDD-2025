/*
	Ejercicio 1: 
	Se pide: Crear un trigger que valide que ante un insert de una o m�s filas en la tabla
	�tems, realice la siguiente validaci�n:
		? Si la orden de compra a la que pertenecen los �tems ingresados corresponde a
		clientes del estado de California, se deber� validar que estas �rdenes puedan tener
		como m�ximo 5 registros en la tabla �tem.
		? Si se insertan m�s �tems de los definidos, el resto de los �tems se deber�n insertar
		en la tabla items_error la cual contiene la misma estructura que la tabla �tems m�s
		un atributo fecha que deber� contener la fecha del d�a en que se trat� de insertar.
	Ej. Si la Orden de Compra tiene 3 items y se realiza un insert masivo de 3 �tems m�s, el
	trigger deber� insertar los 2 primeros en la tabla �tems y el restante en la tabla �tems_error.
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
