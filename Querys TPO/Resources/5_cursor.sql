USE BahiaSerenaDB;
GO

CREATE OR ALTER PROCEDURE dbo.sp_inactivar_habitaciones_fuera_servicio
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Declaración de variables
    DECLARE @id_habitacion INT;
    DECLARE @numero_habitacion VARCHAR(10);
    DECLARE @nombre_habitacion VARCHAR(50);
    DECLARE @habitaciones_procesadas INT = 0;
    
    -- Declaración de cursor
    DECLARE cur_habitaciones_fuera_servicio CURSOR FOR
    SELECT id_habitacion, numero_habitacion, nombre
    FROM dbo.habitacion
    WHERE estado_operativo = 'FUERA_SERVICIO'
    AND fecha_eliminacion IS NULL;
    
    BEGIN TRY
        OPEN cur_habitaciones_fuera_servicio;
        
        -- Fetch primera habitación
        FETCH NEXT FROM cur_habitaciones_fuera_servicio 
        INTO @id_habitacion, @numero_habitacion, @nombre_habitacion;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRANSACTION;
            
            -- Actualización de la habitación
            UPDATE dbo.habitacion
            SET estado_operativo = 'INACTIVA',
                modificado_por = 'sp_inactivar_habitaciones_fuera_servicio',
                fecha_modificacion = GETDATE()
            WHERE id_habitacion = @id_habitacion;
            
            -- Inserción de la alerta
            INSERT INTO dbo.alerta (tipo, descripcion, id_habitacion, creado_por)
            VALUES (
                'MANTENIMIENTO',
                'Habitación ' + @numero_habitacion + ' (' + ISNULL(@nombre_habitacion, 'Sin nombre') + 
                ') inactivada automáticamente desde estado FUERA_SERVICIO',
                @id_habitacion,
                'sp_inactivar_habitaciones_fuera_servicio'
            );
            
            COMMIT TRANSACTION;
            
            -- Incremento del contador de habitaciones procesadas
            SET @habitaciones_procesadas = @habitaciones_procesadas + 1;
            
            -- Fetch siguiente habitación
            FETCH NEXT FROM cur_habitaciones_fuera_servicio 
            INTO @id_habitacion, @numero_habitacion, @nombre_habitacion;
        END
        
        CLOSE cur_habitaciones_fuera_servicio;
        DEALLOCATE cur_habitaciones_fuera_servicio;
        
        -- Resultado de la ejecución
        SELECT 
            @habitaciones_procesadas AS habitaciones_procesadas,
            'Proceso completado exitosamente' AS mensaje;
        
    END TRY
    BEGIN CATCH
        -- Cierre del cursor si es necesario
        IF CURSOR_STATUS('local', 'cur_habitaciones_fuera_servicio') >= 0
        BEGIN
            CLOSE cur_habitaciones_fuera_servicio;
            DEALLOCATE cur_habitaciones_fuera_servicio;
        END
        
        -- Rollback de la transacción si es necesario
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;