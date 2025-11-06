-- Procedure para registrar alertas de forma independiente
CREATE OR ALTER PROCEDURE dbo.sp_registrar_alerta
    @id_cliente INT = NULL,
    @id_habitacion INT = NULL,
    @tipo VARCHAR(50),
    @id_reserva INT = NULL,
    @descripcion VARCHAR(500),
    @creado_por VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.alerta (id_cliente, id_habitacion, tipo, descripcion, id_reserva, creado_por)
    VALUES (@id_cliente, @id_habitacion, @tipo, @descripcion, @id_reserva, ISNULL(@creado_por, SYSTEM_USER));
END

