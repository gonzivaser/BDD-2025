CREATE TABLE auditoria (
    auditID      INT IDENTITY(1,1) PRIMARY KEY,
    nombreTabla  VARCHAR(30) NOT NULL,
    operacion    CHAR(1) CHECK (operacion IN ('I', 'O', 'N', 'D')),
    rowData      VARCHAR(255) NOT NULL,
    usuario      VARCHAR(30) DEFAULT suser_sname(),
    fecha        DATETIME DEFAULT getDate()
);


/*PROCEDURE: PARA INSERTAR DATOS DENTRO DE LA TABLA AUDITORIA*/
CREATE PROCEDURE altaAuditoria 
    @nombreTabla varchar(30), 
    @operacion char(1), 
    @rowData varchar(255)
AS
BEGIN
    INSERT INTO auditoria(nombreTabla, operacion, rowData)
    VALUES (@nombreTabla, @operacion, @rowData)
END

/*CREO TRIGGER DE INSERT*/
CREATE TRIGGER ins_manufact on manufact
AFTER INSERT
AS
DECLARE
@manu_code char(3),
@manu_name varchar(15),
@lead_time smallint,
@state CHAR(2),
@rowData varchar(255)

BEGIN
	DECLARE curInsertados CURSOR FOR 
	SELECT manu_code, manu_name, lead_time, state
	FROM inserted
	
	OPEN curInsertados
	FETCH NEXT FROM curInsertados 
	INTO @manu_code, @manu_name, @lead_time, @state
	WHILE @@fetch_status=0
	BEGIN
		SET @rowData= @manu_code + ' | '+ @manu_name + ' | '+ cast (@lead_time as nvarchar)+' | '+
@state
		EXEC altaAuditoria 'manufact', 'I', @rowData
		FETCH NEXT FROM curInsertados 
		INTO @manu_code, @manu_name, @lead_time, @state
	END
CLOSE curInsertados
DEALLOCATE curInsertados
END


/*CREO TRIGGER DE DELETE*/
CREATE TRIGGER del_manufact ON manufact
AFTER DELETE
AS
DECLARE
@manu_code char(3),
@manu_name varchar(15),
@lead_time smallint,
@state char(2),
@rowData varchar(255)
BEGIN
DECLARE curBorrados CURSOR FOR 
SELECT manu_code, manu_name, lead_time, state
  FROM deleted
OPEN curBorrados

FETCH NEXT FROM curBorrados INTO @manu_code, @manu_name, @lead_time,@state
WHILE @@fetch_status=0
	BEGIN
	SET @rowData= @manu_code + ' | '+ @manu_name + ' | '+ cast (@lead_time as nvarchar)+' | '+@state
	EXEC altaAuditoria 'manufact', 'D', @rowData
	FETCH NEXT FROM curBorrados 
	INTO @manu_code, @manu_name, @lead_time,@state
	END
CLOSE curBorrados
DEALLOCATE curBorrados
END


/*CREO TRIGGER DE UPDATE*/
CREATE TRIGGER upd_manufact ON manufact 
AFTER UPDATE
AS 
DECLARE 
	@old_manu_code CHAR(3),
    @old_manu_name VARCHAR(15),
    @old_lead_time SMALLINT,
    @old_state CHAR(2),

    @new_manu_code CHAR(3),
    @new_manu_name VARCHAR(15),
    @new_lead_time SMALLINT,
    @new_state CHAR(2),

    @rowData VARCHAR(255)
BEGIN 
DECLARE curDeleted CURSOR FOR 
	SELECT 
		manu_code, 
		manu_name, 
		lead_time, 
		state
	FROM 
		deleted
DECLARE curinserted CURSOR FOR 
	SELECT 
		manu_code, 
		manu_name, 
		lead_time, 
		state
	FROM 
		inserted

OPEN curDeleted
OPEN curInserted 

FETCH NEXT FROM curDeleted INTO @old_manu_code, @old_manu_name, @old_lead_time, @old_state
FETCH NEXT FROM curInserted INTO @new_manu_code, @new_manu_name, @new_lead_time, @new_state

WHILE @@FETCH_STATUS = 0
BEGIN 
	/*VIEJOS*/
	SET @rowData = @old_manu_code + ' | ' + @old_manu_name + ' | ' + 
                   CAST(@old_lead_time AS NVARCHAR) + ' | ' + @old_state
    EXEC altaAuditoria 'manufact', 'O', @rowData

	/*NUEVOS*/
	SET @rowData = @new_manu_code + ' | ' + @new_manu_name + ' | ' + 
                   CAST(@new_lead_time AS NVARCHAR) + ' | ' + @new_state
    EXEC altaAuditoria 'manufact', 'N', @rowData

	/*AVANZO CURSOR*/
	FETCH NEXT FROM curDeleted INTO @old_manu_code, @old_manu_name, @old_lead_time, @old_state
    FETCH NEXT FROM curInserted INTO @new_manu_code, @new_manu_name, @new_lead_time, @new_state
END 


CLOSE curDeleted
DEALLOCATE curDeleted

CLOSE curInserted
DEALLOCATE curInserted
END