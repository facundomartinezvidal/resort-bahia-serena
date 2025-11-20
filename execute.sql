-- ===========================================================================
-- ARCHIVO DE DEMOSTRACIÓN - RESORT BAHIA SERENA
-- ===========================================================================
-- Este script demuestra el funcionamiento de:
-- 1. FUNCIÓN: fn_calcular_margen_servicio
-- 2. PROCEDURE: sp_reservar_habitacion
-- 3. CURSOR: sp_inactivar_habitaciones_fuera_servicio
-- 4. TRIGGER: trg_validar_duplicacion_habitacion
-- 5. VISTA: vw_habitaciones_repetidas
-- ===========================================================================

USE BahiaSerenaDB;
GO

SET NOCOUNT ON;

-- ===========================================================================
-- 1. FUNCIÓN: fn_calcular_margen_servicio
-- ===========================================================================
-- Objetivo: Calcular el margen de ganancia (precio - costo) de servicios adicionales
-- Uso: Validar que un servicio tenga margen positivo antes de agregarlo a una reserva
-- ===========================================================================

-- Caso 1: Servicio con margen POSITIVO (Gimnasio)

SELECT 
    id_servicio_adicional,
    nombre,
    costo,
    precio,
    (precio - costo) AS margen_esperado
FROM dbo.servicio_adicional 
WHERE id_servicio_adicional = 7;

DECLARE @margen_gimnasio DECIMAL(10, 2) = dbo.fn_calcular_margen_servicio(7);
PRINT 'Resultado de la función: $' + CAST(@margen_gimnasio AS VARCHAR(10));


-- Caso 2: Crear un servicio con margen NEGATIVO para demostrar validación

-- Modificamos temporalmente el servicio "Traslado aeropuerto" para que tenga margen negativo
UPDATE dbo.servicio_adicional 
SET costo = 80.00, precio = 40.00 
WHERE id_servicio_adicional = 8;

SELECT 
    id_servicio_adicional,
    nombre,
    costo,
    precio,
    (precio - costo) AS margen_esperado
FROM dbo.servicio_adicional 
WHERE id_servicio_adicional = 8;

DECLARE @margen_traslado DECIMAL(10, 2) = dbo.fn_calcular_margen_servicio(8);
PRINT 'Resultado de la función: $' + CAST(@margen_traslado AS VARCHAR(10));

-- Restauramos el servicio a valores normales
UPDATE dbo.servicio_adicional 
SET costo = 20.00, precio = 60.00 
WHERE id_servicio_adicional = 8;

-- ===========================================================================
-- 2. PROCEDURE: sp_reservar_habitacion
-- ===========================================================================
-- Objetivo: Crear reservas validando disponibilidad, clientes, temporadas y servicios
-- Usa la función fn_calcular_margen_servicio para validar servicios adicionales
-- ===========================================================================


-- Caso 1: Intentar reservar con un cliente INACTIVO (debe fallar)
BEGIN TRY
    EXEC dbo.sp_reservar_habitacion
        @id_cliente = 999,  -- Cliente inexistente
        @id_habitacion = 1,
        @fecha_inicio = '2025-12-15',
        @fecha_fin = '2025-12-20';
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH

-- Caso 2: Crear reserva EXITOSA con servicio adicional

-- Obtener ID para la demostración
DECLARE @cliente_demo INT = (SELECT TOP 1 id_cliente FROM cliente WHERE estado = 'ACTIVO' ORDER BY id_cliente);
DECLARE @habitacion_demo INT = (SELECT TOP 1 id_habitacion FROM habitacion WHERE estado_operativo = 'DISPONIBLE' ORDER BY id_habitacion);

-- Crear la reserva
EXEC dbo.sp_reservar_habitacion
    @id_cliente = @cliente_demo,
    @id_habitacion = @habitacion_demo,
    @fecha_inicio = '2025-12-15',
    @fecha_fin = '2025-12-20',
    @id_servicio_adicional = 7,  -- Gimnasio
    @cantidad_servicio = 2;


-- Caso 3: Intentar agregar servicio con margen NEGATIVO (debe fallar)

-- Crear servicio con margen negativo temporalmente
UPDATE dbo.servicio_adicional 
SET costo = 100.00, precio = 50.00 
WHERE id_servicio_adicional = 8;

DECLARE @cliente_demo INT = (SELECT TOP 1 id_cliente FROM cliente WHERE estado = 'ACTIVO' ORDER BY id_cliente);
DECLARE @habitacion_demo INT = (SELECT TOP 1 id_habitacion FROM habitacion WHERE estado_operativo = 'DISPONIBLE' ORDER BY id_habitacion);

BEGIN TRY
    EXEC dbo.sp_reservar_habitacion
        @id_cliente = @cliente_demo,
        @id_habitacion = @habitacion_demo,
        @fecha_inicio = '2026-01-10',
        @fecha_fin = '2026-01-15',
        @id_servicio_adicional = 8;  -- Servicio con margen negativo
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH

-- Restaurar servicio
UPDATE dbo.servicio_adicional 
SET costo = 40.00, precio = 100.00 
WHERE id_servicio_adicional = 8;


-- ===========================================================================
-- 3. CURSOR: sp_inactivar_habitaciones_fuera_servicio
-- ===========================================================================
-- Objetivo: Recorrer habitaciones FUERA_SERVICIO y marcarlas como INACTIVAS
-- Genera alertas de MANTENIMIENTO automáticamente
-- ===========================================================================

-- Modificamos temporalmente habitaciones a FUERA_SERVICIO
UPDATE habitacion SET estado_operativo = 'FUERA_SERVICIO' WHERE estado_operativo = 'DISPONIBLE' AND id_habitacion = 1;
UPDATE habitacion SET estado_operativo = 'FUERA_SERVICIO' WHERE estado_operativo = 'DISPONIBLE' AND id_habitacion = 2;
UPDATE habitacion SET estado_operativo = 'FUERA_SERVICIO' WHERE estado_operativo = 'DISPONIBLE' AND id_habitacion = 3;

-- Seleccionar estado antes de ejecutar el cursor
SELECT 
    estado_operativo,
    COUNT(*) AS cantidad
FROM habitacion
GROUP BY estado_operativo
ORDER BY estado_operativo;

SELECT 
    id_habitacion,
    numero_habitacion,
    nombre,
    estado_operativo
FROM habitacion
WHERE estado_operativo = 'FUERA_SERVICIO';

-- Ejecutar el procedimiento que usa el cursor
EXEC dbo.sp_inactivar_habitaciones_fuera_servicio

SELECT 
    estado_operativo,
    COUNT(*) AS cantidad
FROM habitacion
GROUP BY estado_operativo
ORDER BY estado_operativo;

SELECT 
    id_habitacion,
    numero_habitacion,
    nombre,
    estado_operativo,
    modificado_por,
    fecha_modificacion
FROM habitacion
WHERE estado_operativo = 'INACTIVA';


SELECT 
    tipo,
    descripcion,
    creado_por,
    fecha_creacion
FROM alerta
WHERE creado_por = 'sp_inactivar_habitaciones_fuera_servicio'
ORDER BY fecha_creacion DESC;

-- ===========================================================================
-- 4. TRIGGER: trg_validar_duplicacion_habitacion
-- ===========================================================================
-- Objetivo: Prevenir reservas duplicadas (mismo cliente, habitación y fecha)
-- Genera alertas de REPETICION cuando detecta un intento de duplicación
-- Se valida usando el procedimiento sp_reservar_habitacion
-- ===========================================================================


-- Contar alertas de repetición antes del intento
DECLARE @alertas_antes INT = (SELECT COUNT(*) FROM alerta WHERE tipo = 'REPETICION');
PRINT 'Alertas de REPETICION antes: ' + CAST(@alertas_antes AS VARCHAR);

DECLARE @fecha_trigger_inicio DATETIME = GETDATE();
DECLARE @fecha_trigger_fin DATETIME = '2025-12-30';

-- Buscar un cliente ACTIVO que NO tenga reservas activas en conflicto con las fechas seleccionadas
-- Esto asegura que se cree una NUEVA reserva y no se agregue detalle a una existente
DECLARE @cliente_trigger INT = (
    SELECT TOP 1 c.id_cliente 
    FROM cliente c
    WHERE c.estado = 'ACTIVO' 
    AND NOT EXISTS (
        SELECT 1 
        FROM reserva r
        WHERE r.id_cliente = c.id_cliente
        AND r.estado_reserva NOT IN ('CANCELADA', 'COMPLETADA')
        AND r.fecha_eliminacion IS NULL
        AND (
            @fecha_trigger_inicio BETWEEN r.fecha_checkin AND r.fecha_checkout OR
            @fecha_trigger_fin BETWEEN r.fecha_checkin AND r.fecha_checkout OR
            r.fecha_checkin BETWEEN @fecha_trigger_inicio AND @fecha_trigger_fin
        )
    )
    ORDER BY c.id_cliente
);

-- Si todos tienen reservas (muy improbable), usar fallback
IF @cliente_trigger IS NULL
BEGIN
     SELECT TOP 1 @cliente_trigger = id_cliente FROM cliente WHERE estado = 'ACTIVO';
END

-- Buscar una habitación disponible que NO tenga reservas en el rango de fechas seleccionado
DECLARE @habitacion_trigger INT = (
    SELECT TOP 1 h.id_habitacion 
    FROM habitacion h
    WHERE h.estado_operativo = 'DISPONIBLE' 
    AND NOT EXISTS (
        SELECT 1 
        FROM detalle_reserva dr
        INNER JOIN reserva r ON dr.id_reserva = r.id_reserva
        WHERE dr.id_habitacion = h.id_habitacion
        AND r.estado_reserva NOT IN ('CANCELADA', 'COMPLETADA')
        AND (
            @fecha_trigger_inicio BETWEEN dr.fecha_checkin AND dr.fecha_checkout OR
            @fecha_trigger_fin BETWEEN dr.fecha_checkin AND dr.fecha_checkout OR
            dr.fecha_checkin BETWEEN @fecha_trigger_inicio AND @fecha_trigger_fin
        )
    )
    ORDER BY h.id_habitacion
);

-- Si no encuentra habitación libre por fechas, tomar cualquiera disponible (el SP validará y dará error de ocupada si corresponde, pero no ID inválido)
IF @habitacion_trigger IS NULL
BEGIN
    SELECT TOP 1 @habitacion_trigger = id_habitacion 
    FROM habitacion 
    WHERE estado_operativo = 'DISPONIBLE';
END

PRINT '  Parámetros de la reserva:';
PRINT '    • Cliente ID: ' + CAST(@cliente_trigger AS VARCHAR);
PRINT '    • Habitación ID: ' + CAST(@habitacion_trigger AS VARCHAR);
PRINT '    • Check-in: ' + CONVERT(VARCHAR, @fecha_trigger_inicio, 120);
PRINT '    • Check-out: ' + CONVERT(VARCHAR, @fecha_trigger_fin, 120);
PRINT '';

-- Crear la primera reserva
EXEC dbo.sp_reservar_habitacion
    @id_cliente = @cliente_trigger,
    @id_habitacion = @habitacion_trigger,
    @fecha_inicio = @fecha_trigger_inicio,
    @fecha_fin = @fecha_trigger_fin;

-- Obtener y mostrar detalles de la reserva recién creada
DECLARE @id_reserva_creada INT = (
    SELECT TOP 1 r.id_reserva 
    FROM reserva r
    INNER JOIN detalle_reserva dr ON r.id_reserva = dr.id_reserva
    WHERE r.id_cliente = @cliente_trigger 
    AND dr.id_habitacion = @habitacion_trigger
    AND dr.fecha_checkin = @fecha_trigger_inicio
    ORDER BY r.id_reserva DESC
);

PRINT '';
PRINT '  ✓ Primera reserva creada exitosamente';
PRINT '    • ID Reserva: ' + CAST(@id_reserva_creada AS VARCHAR);
PRINT '    • Cliente: ' + CAST(@cliente_trigger AS VARCHAR);
PRINT '    • Habitación: ' + CAST(@habitacion_trigger AS VARCHAR);
PRINT '    • Fechas: ' + CONVERT(VARCHAR, @fecha_trigger_inicio, 103) + ' al ' + CONVERT(VARCHAR, @fecha_trigger_fin, 103);
PRINT '';


-- Paso 2: Intentar DUPLICAR la misma reserva (debe fallar por el trigger)

BEGIN TRY
    -- Intentar crear la reserva duplicada usando el mismo procedimiento
    EXEC dbo.sp_reservar_habitacion
        @id_cliente = @cliente_trigger,
        @id_habitacion = @habitacion_trigger,
        @fecha_inicio = @fecha_trigger_inicio,
        @fecha_fin = @fecha_trigger_fin;

END TRY
BEGIN CATCH
    PRINT 'TRIGGER ACTIVADO - Error capturado:';
    PRINT '    ' + ERROR_MESSAGE();
    PRINT '';
    PRINT 'El trigger bloqueó exitosamente la duplicación';
END CATCH

PRINT '';

-- Verificar que se generó la alerta
DECLARE @alertas_despues INT = (SELECT COUNT(*) FROM alerta WHERE tipo = 'REPETICION');
PRINT 'Alertas de REPETICION después: ' + CAST(@alertas_despues AS VARCHAR);

IF @alertas_despues > @alertas_antes
    PRINT 'Alerta de REPETICION generada automáticamente por el trigger';
ELSE
    PRINT 'No se generó alerta adicional (puede que ya existiera)';

-- Ultima alerta de REPETICION generada
SELECT TOP 1
    tipo,
    descripcion,
    id_cliente,
    id_habitacion,
    id_reserva,
    creado_por,
    fecha_creacion
FROM alerta
WHERE tipo = 'REPETICION'
ORDER BY fecha_creacion DESC;

PRINT '';

-- Limpieza: Eliminar las reservas de prueba (BLOQUE AUTONOMO)
DELETE FROM alerta
WHERE id_reserva IN (
    SELECT id_reserva 
    FROM reserva 
    WHERE id_cliente = (SELECT TOP 1 id_cliente FROM cliente WHERE estado = 'ACTIVO' ORDER BY id_cliente)
    AND fecha_checkin >= CAST(GETDATE() AS DATE) -- Reservas desde hoy en adelante
);

-- Eliminar alertas de repetición huerfanas recientes de este cliente
DELETE FROM alerta
WHERE tipo = 'REPETICION'
AND id_cliente = (SELECT TOP 1 id_cliente FROM cliente WHERE estado = 'ACTIVO' ORDER BY id_cliente)
AND fecha_creacion >= DATEADD(MINUTE, -30, GETDATE())
AND id_reserva IS NULL;

-- 2. Eliminar consumos
DELETE FROM consumo
WHERE id_reserva IN (
    SELECT id_reserva 
    FROM reserva 
    WHERE id_cliente = (SELECT TOP 1 id_cliente FROM cliente WHERE estado = 'ACTIVO' ORDER BY id_cliente)
    AND fecha_checkin >= CAST(GETDATE() AS DATE)
);

-- 3. Eliminar detalles de reserva
DELETE FROM detalle_reserva
WHERE id_reserva IN (
    SELECT id_reserva 
    FROM reserva 
    WHERE id_cliente = (SELECT TOP 1 id_cliente FROM cliente WHERE estado = 'ACTIVO' ORDER BY id_cliente)
    AND fecha_checkin >= CAST(GETDATE() AS DATE)
);

-- 4. Eliminar la reserva
DELETE FROM reserva
WHERE id_cliente = (SELECT TOP 1 id_cliente FROM cliente WHERE estado = 'ACTIVO' ORDER BY id_cliente)
AND fecha_checkin >= CAST(GETDATE() AS DATE);

PRINT 'Datos de prueba eliminados exitosamente';


-- ===========================================================================
-- 5. VISTA: vw_habitaciones_repetidas
-- ===========================================================================
-- Objetivo: Mostrar clientes con múltiples intentos de reserva en la misma habitación
-- Agrupa alertas de REPETICION para detectar patrones sospechosos
-- ===========================================================================

SELECT * FROM dbo.vw_habitaciones_repetidas ORDER BY dbo.vw_habitaciones_repetidas.id_cliente, dbo.vw_habitaciones_repetidas.cantidad_intentos DESC;

