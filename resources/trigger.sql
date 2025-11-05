CREATE OR ALTER TRIGGER trg_validar_duplicacion_habitacion
ON dbo.detalle_reserva
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @id_cliente INT;
        DECLARE @id_habitacion INT;
        DECLARE @fecha_checkin DATETIME;
        DECLARE @fecha_checkout DATETIME;
        DECLARE @id_reserva INT;
        DECLARE @precio_noche DECIMAL(10,2);
        DECLARE @cant_noches INT;

        -- Obtener datos del registro a insertar
        SELECT 
            @id_reserva = i.id_reserva,
            @id_habitacion = i.id_habitacion,
            @fecha_checkin = i.fecha_checkin,
            @fecha_checkout = i.fecha_checkout,
            @precio_noche = i.precio_noche,
            @cant_noches = i.cant_noches,
            @id_cliente = r.id_cliente
        FROM inserted i
        INNER JOIN dbo.reserva r ON i.id_reserva = r.id_reserva;

        -- Verificar si existe duplicación: mismo cliente, misma habitación, mismo check-in
        IF EXISTS (
            SELECT 1
            FROM dbo.detalle_reserva dr
            INNER JOIN dbo.reserva r ON dr.id_reserva = r.id_reserva
            WHERE r.id_cliente = @id_cliente
            AND dr.id_habitacion = @id_habitacion
            AND dr.fecha_checkin = @fecha_checkin
            AND r.estado_reserva NOT IN ('CANCELADA', 'COMPLETADA')
            AND r.fecha_eliminacion IS NULL
            AND dr.fecha_eliminacion IS NULL
        )
        BEGIN
            -- Registrar alerta
            INSERT INTO dbo.alerta (tipo, descripcion, id_cliente, id_reserva, id_habitacion, creado_por)
            VALUES (
                'REPETICION',
                'Intento de duplicación bloqueado: mismo cliente, misma habitación, mismo check-in (' + 
                CONVERT(VARCHAR, @fecha_checkin, 103) + ')',
                @id_cliente,
                @id_reserva,
                @id_habitacion,
                'trg_validar_duplicacion_habitacion'
            );

            -- Lanzar error (no hace falta ROLLBACK porque el INSERT nunca se ejecutó)
            THROW 50010, 'No se puede reservar la misma habitación para el mismo cliente en el mismo check-in. Operación bloqueada y registrada en alertas.', 1;
        END
        ELSE
        BEGIN
            -- Si no hay duplicación, realizar el INSERT original preservando auditoría
            INSERT INTO dbo.detalle_reserva (
                id_reserva, 
                id_habitacion, 
                precio_noche, 
                fecha_checkin, 
                fecha_checkout, 
                cant_noches,
                creado_por
            )
            SELECT 
                id_reserva,
                id_habitacion,
                precio_noche,
                fecha_checkin,
                fecha_checkout,
                cant_noches,
                COALESCE(creado_por, SYSTEM_USER)
            FROM inserted;
        END

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
