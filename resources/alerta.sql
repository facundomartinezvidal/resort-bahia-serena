CREATE OR ALTER PROCEDURE dbo.sp_registrar_alerta
    @id_cliente INT = NULL,
    @id_habitacion INT = NULL,
    @tipo VARCHAR(50),
    @descripcion VARCHAR(500),
    @creado_por VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.alerta (id_cliente, id_habitacion, tipo, descripcion, creado_por)
    VALUES (@id_cliente, @id_habitacion, @tipo, @descripcion, COALESCE(@creado_por, SYSTEM_USER));
END

