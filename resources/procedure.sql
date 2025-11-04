
CREATE OR ALTER PROCEDURE dbo.sp_reservar_habitacion
    @id_cliente INT, @id_habitacion INT, @fecha_inicio DATE, @fecha_fin DATE
AS
BEGIN

    -- Verificar parametros de entrada
    IF @id_cliente IS NULL OR @id_cliente < 0
    BEGIN
        THROW 50000, 'El id_cliente es inválido.', 1;
    END
    IF @id_habitacion IS NULL OR @id_habitacion < 0
    BEGIN
        THROW 50001, 'El id_habitacion es inválido.', 1;
    END
    IF @fecha_inicio IS NULL OR @fecha_fin IS NULL OR @fecha_inicio >= @fecha_fin
    BEGIN
        THROW 50002, 'Las fechas de reserva son inválidas.', 1;
    END


    -- Verificar si el cliente existe
    IF NOT EXISTS (SELECT 1 FROM dbo.cliente WHERE id_cliente = @id_cliente)
    BEGIN
        THROW 50003, 'El cliente no existe.', 1;
    END

    -- Verificar si la habitación existe y si está disponible
    IF NOT EXISTS (SELECT 1 FROM dbo.habitacion WHERE id_habitacion = @id_habitacion AND estado_operativo = 'DISPONIBLE')
    BEGIN
        THROW 50004, 'La habitación no existe.', 1;
    END



    -- Verificar que el cliente no haya intentado reservar la misma habitación
    IF EXISTS (
        SELECT 1 FROM dbo.reserva
        INNER JOIN dbo.detalle_reserva dr on dbo.reserva.id_reserva = dr.id_reserva
        WHERE dbo.reserva.id_cliente = @id_cliente
        AND dr.id_habitacion = @id_habitacion
        AND dbo.reserva.estado_reserva != 'CANCELADA'
        AND (@fecha_inicio BETWEEN dr.fecha_checkin AND dr.fecha_checkout
             OR @fecha_fin BETWEEN dr.fecha_checkin AND dr.fecha_checkout
             OR dr.fecha_checkin BETWEEN @fecha_inicio AND @fecha_fin)
    )
    BEGIN
        DECLARE @id_reserva_error INT = (
            SELECT TOP 1 dbo.reserva.id_reserva FROM dbo.reserva
            INNER JOIN dbo.detalle_reserva dr on dbo.reserva.id_reserva = dr.id_reserva
            WHERE dbo.reserva.id_cliente = @id_cliente
            AND dr.id_habitacion = @id_habitacion
            AND dbo.reserva.estado_reserva != 'CANCELADA'
            AND (@fecha_inicio BETWEEN dr.fecha_checkin AND dr.fecha_checkout
                 OR @fecha_fin BETWEEN dr.fecha_checkin AND dr.fecha_checkout
                 OR dr.fecha_checkin BETWEEN @fecha_inicio AND @fecha_fin)
        );
        INSERT INTO dbo.alerta (id_cliente, id_reserva,  id_habitacion, tipo, descripcion)
        VALUES (@id_cliente, @id_reserva_error, @id_habitacion, 'REPETICION', 'El cliente ya ha intentado reservar esta habitación en las fechas solicitadas.');
        THROW 50005, 'El cliente ya ha intentado reservar esta habitación en las fechas solicitadas.', 1;
    END

    -- Verificar si la habitación está reservada en las fechas solicitadas POR OTRO CLIENTE
    IF EXISTS (
        SELECT 1 FROM dbo.reserva
        INNER JOIN dbo.detalle_reserva dr on dbo.reserva.id_reserva = dr.id_reserva
        WHERE dr.id_habitacion = @id_habitacion
        AND dbo.reserva.estado_reserva != 'CANCELADA'
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
        DECLARE @id_temporada INT =
            (SELECT TOP 1 id_temporada
                FROM dbo.temporada
                WHERE @fecha_inicio BETWEEN fecha_inicio AND fecha_fin
            );

    -- Obtener precio por noche y calcular cantidad de noches
        DECLARE @precio_noche DECIMAL(10,2) =
            (SELECT t.precio_noche
                FROM dbo.habitacion
                INNER JOIN dbo.tipo_habitacion th on th.id_tipo_habitacion = dbo.habitacion.id_tipo_habitacion
                INNER JOIN dbo.tarifa t on th.id_tipo_habitacion = t.id_tipo_habitacion
                WHERE id_habitacion = @id_habitacion
                AND t.id_temporada = @id_temporada
            );

    DECLARE @cant_noches INT = DATEDIFF(DAY, @fecha_inicio, @fecha_fin);


    -- Verificar si el cliente quiere agregar un detalle a una reserva existente en las mismas fechas
    IF EXISTS (
        SELECT 1 FROM  dbo.reserva r
                 WHERE id_cliente = @id_cliente
                    AND (r.estado_reserva != 'ACTIVA' OR r.estado_reserva != 'FINALIZADA' OR estado_reserva != 'CANCELADA')
                    AND (@fecha_inicio BETWEEN r.fecha_checkin AND r.fecha_checkout
                         OR @fecha_fin BETWEEN r.fecha_checkin AND r.fecha_checkout
                         OR r.fecha_checkin BETWEEN @fecha_inicio AND @fecha_fin)
    )
        BEGIN
            DECLARE @id_reserva_existente INT = (
                SELECT TOP 1 r.id_reserva FROM  dbo.reserva r
                         WHERE id_cliente = @id_cliente
                            AND (r.estado_reserva != 'ACTIVA' OR r.estado_reserva != 'FINALIZADA' OR estado_reserva != 'CANCELADA')
                            AND (@fecha_inicio BETWEEN r.fecha_checkin AND r.fecha_checkout
                                 OR @fecha_fin BETWEEN r.fecha_checkin AND r.fecha_checkout
                                 OR r.fecha_checkin BETWEEN @fecha_inicio AND @fecha_fin)
            );

            DECLARE @total_actual DECIMAL(10,2) = (
                SELECT total FROM dbo.reserva WHERE id_reserva = @id_reserva_existente
            );

            -- Actualizar el total de la reserva existente
            UPDATE dbo.reserva
            SET total = (@precio_noche * @cant_noches) + @total_actual
            WHERE id_reserva = @id_reserva_existente


            INSERT INTO dbo.detalle_reserva (id_reserva, id_habitacion, precio_noche, fecha_checkin, fecha_checkout, cant_noches)
            VALUES (@id_reserva_existente, @id_habitacion, @precio_noche, @fecha_inicio, @fecha_fin, @cant_noches);
            PRINT ('========================================')
            PRINT ('      HABITACIÓN AGREGADA A RESERVA EXISTENTE')
            PRINT ('========================================')
            PRINT ('ID Reserva: ' + CAST(@id_reserva_existente AS VARCHAR(10)))
            PRINT ('ID Habitación: ' + CAST(@id_habitacion AS VARCHAR(10)))
            PRINT ('ID Cliente: ' + CAST(@id_cliente AS VARCHAR(10)))
            PRINT ('Fecha Check-in: ' + CAST(@fecha_inicio AS VARCHAR(20)))
            PRINT ('Fecha Check-out: ' + CAST(@fecha_fin AS VARCHAR(20)))
            PRINT ('Cantidad de Noches: ' + CAST(@cant_noches AS VARCHAR(10)))
            PRINT ('Precio por Noche: $' + CAST(@precio_noche AS VARCHAR(15)))
            PRINT ('Total: $' + CAST(((@precio_noche * @cant_noches) + @total_actual ) AS VARCHAR(15)))
            PRINT ('========================================')
        END
    ELSE
    BEGIN
        -- Continuar con la creación de la reserva
        INSERT INTO dbo.reserva (id_cliente, fecha_checkin, fecha_checkout, creado_por)
        VALUES (@id_cliente, @fecha_inicio, @fecha_fin, SYSTEM_USER);

        -- Obtener el ID de la reserva recién creada
        DECLARE @id_reserva INT = SCOPE_IDENTITY();



        -- Actualizar el total de la reserva
        UPDATE dbo.reserva
        SET total = @precio_noche * @cant_noches
        WHERE id_reserva = @id_reserva

        -- Crear el detalle de la reserva
        INSERT INTO detalle_reserva(id_reserva, id_habitacion, precio_noche, fecha_checkin, fecha_checkout, cant_noches)
        VALUES (@id_reserva, @id_habitacion, @precio_noche, @fecha_inicio, @fecha_fin, @cant_noches);

        PRINT ('========================================')
        PRINT ('      RESERVA CREADA EXITOSAMENTE')
        PRINT ('========================================')
        PRINT ('ID Reserva: ' + CAST(@id_reserva AS VARCHAR(10)))
        PRINT ('ID Habitación: ' + CAST(@id_habitacion AS VARCHAR(10)))
        PRINT ('ID Cliente: ' + CAST(@id_cliente AS VARCHAR(10)))
        PRINT ('Fecha Check-in: ' + CAST(@fecha_inicio AS VARCHAR(20)))
        PRINT ('Fecha Check-out: ' + CAST(@fecha_fin AS VARCHAR(20)))
        PRINT ('Cantidad de Noches: ' + CAST(@cant_noches AS VARCHAR(10)))
        PRINT ('Precio por Noche: $' + CAST(@precio_noche AS VARCHAR(15)))
        PRINT ('Total: $' + CAST(@precio_noche * @cant_noches AS VARCHAR(15)))
        PRINT ('========================================')

    END


END


