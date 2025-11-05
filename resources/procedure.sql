CREATE OR ALTER PROCEDURE dbo.sp_reservar_habitacion
    @id_cliente INT, 
    @id_habitacion INT, 
    @fecha_inicio DATETIME, 
    @fecha_fin DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verificar parametros de entrada
        IF @id_cliente IS NULL OR @id_cliente <= 0
        BEGIN
            THROW 50000, 'El id_cliente es inválido.', 1;
        END
        
        IF @id_habitacion IS NULL OR @id_habitacion <= 0
        BEGIN
            THROW 50001, 'El id_habitacion es inválido.', 1;
        END
        
        IF @fecha_inicio IS NULL OR @fecha_fin IS NULL OR @fecha_inicio >= @fecha_fin
        BEGIN
            THROW 50002, 'Las fechas de reserva son inválidas.', 1;
        END

        -- Validar que la fecha de check-in no sea en el pasado
        IF @fecha_inicio < CAST(GETDATE() AS DATE)
        BEGIN
            THROW 50009, 'La fecha de check-in no puede ser anterior a la fecha actual.', 1;
        END

        -- Verificar si el cliente existe, está activo y no está eliminado
        IF NOT EXISTS (
            SELECT 1 FROM dbo.cliente 
            WHERE id_cliente = @id_cliente 
            AND estado = 'ACTIVO'
            AND fecha_eliminacion IS NULL
        )
        BEGIN
            THROW 50003, 'El cliente no existe, no está activo o fue eliminado.', 1;
        END

        -- Verificar si la habitación existe, está disponible y no está eliminada
        IF NOT EXISTS (
            SELECT 1 FROM dbo.habitacion 
            WHERE id_habitacion = @id_habitacion 
            AND estado_operativo = 'DISPONIBLE'
            AND fecha_eliminacion IS NULL
        )
        BEGIN
            THROW 50004, 'La habitación no existe, no está disponible o fue eliminada.', 1;
        END

        -- Verificar que el cliente no haya intentado reservar la misma habitación
        IF EXISTS (
            SELECT 1 FROM dbo.reserva r
            INNER JOIN dbo.detalle_reserva dr on r.id_reserva = dr.id_reserva
            WHERE r.id_cliente = @id_cliente
            AND dr.id_habitacion = @id_habitacion
            AND r.estado_reserva NOT IN ('CANCELADA', 'COMPLETADA')
            AND r.fecha_eliminacion IS NULL
            AND dr.fecha_eliminacion IS NULL
            AND (@fecha_inicio BETWEEN dr.fecha_checkin AND dr.fecha_checkout
                 OR @fecha_fin BETWEEN dr.fecha_checkin AND dr.fecha_checkout
                 OR dr.fecha_checkin BETWEEN @fecha_inicio AND @fecha_fin)
        )
        BEGIN
            DECLARE @id_reserva_error INT = (
                SELECT TOP 1 r.id_reserva FROM dbo.reserva r
                INNER JOIN dbo.detalle_reserva dr on r.id_reserva = dr.id_reserva
                WHERE r.id_cliente = @id_cliente
                AND dr.id_habitacion = @id_habitacion
                AND r.estado_reserva NOT IN ('CANCELADA', 'COMPLETADA')
                AND r.fecha_eliminacion IS NULL
                AND dr.fecha_eliminacion IS NULL
                AND (@fecha_inicio BETWEEN dr.fecha_checkin AND dr.fecha_checkout
                     OR @fecha_fin BETWEEN dr.fecha_checkin AND dr.fecha_checkout
                     OR dr.fecha_checkin BETWEEN @fecha_inicio AND @fecha_fin)
            );
            INSERT INTO dbo.alerta (id_cliente, id_reserva, id_habitacion, tipo, descripcion)
            VALUES (@id_cliente, @id_reserva_error, @id_habitacion, 'REPETICION', 'El cliente ya ha intentado reservar esta habitación en las fechas solicitadas.');
            THROW 50005, 'El cliente ya ha intentado reservar esta habitación en las fechas solicitadas.', 1;
        END

        -- Verificar si la habitación está reservada en las fechas solicitadas POR OTRO CLIENTE
        IF EXISTS (
            SELECT 1 FROM dbo.reserva r
            INNER JOIN dbo.detalle_reserva dr on r.id_reserva = dr.id_reserva
            WHERE dr.id_habitacion = @id_habitacion
            AND r.estado_reserva NOT IN ('CANCELADA', 'COMPLETADA')
            AND r.fecha_eliminacion IS NULL
            AND dr.fecha_eliminacion IS NULL
            AND (@fecha_inicio BETWEEN dr.fecha_checkin AND dr.fecha_checkout
                 OR @fecha_fin BETWEEN dr.fecha_checkin AND dr.fecha_checkout
                 OR dr.fecha_checkin BETWEEN @fecha_inicio AND @fecha_fin)
        )
        BEGIN
            INSERT INTO dbo.alerta (id_cliente, id_habitacion, tipo, descripcion)
            VALUES (@id_cliente, @id_habitacion, 'ERROR', 'La habitación ya está reservada en las fechas solicitadas.');
            THROW 50006, 'La habitación ya está reservada en las fechas solicitadas.', 1;
        END

        -- Obtener temporada actual
        DECLARE @id_temporada INT = (
            SELECT TOP 1 id_temporada
            FROM dbo.temporada
            WHERE @fecha_inicio BETWEEN fecha_inicio AND fecha_fin
            AND fecha_eliminacion IS NULL
        );

        -- Validar que exista temporada para la fecha
        IF @id_temporada IS NULL
        BEGIN
            INSERT INTO dbo.alerta (id_cliente, id_habitacion, tipo, descripcion)
            VALUES (@id_cliente, @id_habitacion, 'ERROR', 'No existe temporada vigente para la fecha de check-in solicitada.');
            THROW 50007, 'No existe temporada vigente para la fecha de check-in.', 1;
        END

        -- Obtener precio por noche
        DECLARE @precio_noche DECIMAL(10,2) = (
            SELECT t.precio_noche
            FROM dbo.habitacion
            INNER JOIN dbo.tipo_habitacion th on th.id_tipo_habitacion = dbo.habitacion.id_tipo_habitacion
            INNER JOIN dbo.tarifa t on th.id_tipo_habitacion = t.id_tipo_habitacion
            WHERE id_habitacion = @id_habitacion
            AND t.id_temporada = @id_temporada
            AND t.fecha_eliminacion IS NULL
        );

        -- Validar que exista tarifa para el tipo de habitación y temporada
        IF @precio_noche IS NULL
        BEGIN
            INSERT INTO dbo.alerta (id_cliente, id_habitacion, tipo, descripcion)
            VALUES (@id_cliente, @id_habitacion, 'ERROR', 'No existe tarifa vigente para el tipo de habitación en la temporada solicitada.');
            THROW 50008, 'No existe tarifa vigente para el tipo de habitación en la temporada solicitada.', 1;
        END

        DECLARE @cant_noches INT = DATEDIFF(DAY, @fecha_inicio, @fecha_fin);

        -- Verificar si el cliente quiere agregar un detalle a una reserva existente en las mismas fechas
        IF EXISTS (
            SELECT 1 FROM dbo.reserva r
            WHERE id_cliente = @id_cliente
            AND r.estado_reserva NOT IN ('COMPLETADA', 'CANCELADA')
            AND r.fecha_eliminacion IS NULL
            AND (@fecha_inicio BETWEEN r.fecha_checkin AND r.fecha_checkout
                 OR @fecha_fin BETWEEN r.fecha_checkin AND r.fecha_checkout
                 OR r.fecha_checkin BETWEEN @fecha_inicio AND @fecha_fin)
        )
        BEGIN
            DECLARE @id_reserva_existente INT = (
                SELECT TOP 1 r.id_reserva FROM dbo.reserva r
                WHERE id_cliente = @id_cliente
                AND r.estado_reserva NOT IN ('COMPLETADA', 'CANCELADA')
                AND r.fecha_eliminacion IS NULL
                AND (@fecha_inicio BETWEEN r.fecha_checkin AND r.fecha_checkout
                     OR @fecha_fin BETWEEN r.fecha_checkin AND r.fecha_checkout
                     OR r.fecha_checkin BETWEEN @fecha_inicio AND @fecha_fin)
            );

            DECLARE @total_actual DECIMAL(10,2) = (
                SELECT total FROM dbo.reserva WHERE id_reserva = @id_reserva_existente
            );

            DECLARE @nuevo_total DECIMAL(10,2) = (@precio_noche * @cant_noches) + @total_actual;

            -- Actualizar el total de la reserva existente con auditoría
            UPDATE dbo.reserva
            SET total = @nuevo_total,
                modificado_por = SYSTEM_USER,
                fecha_modificacion = GETDATE()
            WHERE id_reserva = @id_reserva_existente;

            -- Insertar el nuevo detalle de reserva
            INSERT INTO dbo.detalle_reserva (id_reserva, id_habitacion, precio_noche, fecha_checkin, fecha_checkout, cant_noches)
            VALUES (@id_reserva_existente, @id_habitacion, @precio_noche, @fecha_inicio, @fecha_fin, @cant_noches);
            
            COMMIT TRANSACTION;

            -- Resultado estructurado
            SELECT 
                @id_reserva_existente AS id_reserva,
                'HABITACION_AGREGADA' AS operacion,
                @id_cliente AS id_cliente,
                @id_habitacion AS id_habitacion,
                @fecha_inicio AS fecha_checkin,
                @fecha_fin AS fecha_checkout,
                @cant_noches AS cantidad_noches,
                @precio_noche AS precio_noche,
                @nuevo_total AS total_reserva,
                'Habitación agregada exitosamente a reserva existente' AS mensaje;
            
            RETURN;
        END
        ELSE
        BEGIN
            -- Crear nueva reserva
            INSERT INTO dbo.reserva (id_cliente, fecha_checkin, fecha_checkout, creado_por, total)
            VALUES (@id_cliente, @fecha_inicio, @fecha_fin, SYSTEM_USER, @precio_noche * @cant_noches);

            -- Obtener el ID de la reserva recién creada
            DECLARE @id_reserva INT = SCOPE_IDENTITY();

            -- Crear el detalle de la reserva
            INSERT INTO detalle_reserva(id_reserva, id_habitacion, precio_noche, fecha_checkin, fecha_checkout, cant_noches)
            VALUES (@id_reserva, @id_habitacion, @precio_noche, @fecha_inicio, @fecha_fin, @cant_noches);

            COMMIT TRANSACTION;

            -- Resultado estructurado
            SELECT 
                @id_reserva AS id_reserva,
                'RESERVA_CREADA' AS operacion,
                @id_cliente AS id_cliente,
                @id_habitacion AS id_habitacion,
                @fecha_inicio AS fecha_checkin,
                @fecha_fin AS fecha_checkout,
                @cant_noches AS cantidad_noches,
                @precio_noche AS precio_noche,
                @precio_noche * @cant_noches AS total_reserva,
                'Reserva creada exitosamente' AS mensaje;
            
            RETURN;
        END

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END


