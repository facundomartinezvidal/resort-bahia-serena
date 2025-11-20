
USE BahiaSerenaDB;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

PRINT '==========================================================';
PRINT ' INICIANDO SEEDING MASIVO DE DATOS PARA PRESENTACIÓN';
PRINT '==========================================================';

-- ==============================================================================
-- 1. LIMPIEZA (Opcional: Comentar si se quieren mantener datos previos)
-- ==============================================================================
PRINT '1. Limpiando tablas...';
-- Desactivar constraints temporalmente para borrado rápido
ALTER TABLE detalle_reserva NOCHECK CONSTRAINT ALL;
ALTER TABLE reserva NOCHECK CONSTRAINT ALL;
ALTER TABLE factura NOCHECK CONSTRAINT ALL;
ALTER TABLE detalle_factura NOCHECK CONSTRAINT ALL;
ALTER TABLE pago NOCHECK CONSTRAINT ALL;
ALTER TABLE consumo NOCHECK CONSTRAINT ALL;

DELETE FROM alerta;
DELETE FROM pago;
DELETE FROM detalle_factura;
DELETE FROM factura;
DELETE FROM consumo;
DELETE FROM detalle_reserva;
DELETE FROM reserva;
DELETE FROM habitacion;
DELETE FROM tarifa;
DELETE FROM tipo_habitacion;
DELETE FROM temporada;
DELETE FROM vista;
DELETE FROM servicio_adicional;
DELETE FROM cliente;

-- Reactivar constraints
ALTER TABLE detalle_reserva CHECK CONSTRAINT ALL;
ALTER TABLE reserva CHECK CONSTRAINT ALL;
ALTER TABLE factura CHECK CONSTRAINT ALL;
ALTER TABLE detalle_factura CHECK CONSTRAINT ALL;
ALTER TABLE pago CHECK CONSTRAINT ALL;
ALTER TABLE consumo CHECK CONSTRAINT ALL;

-- Resetear contadores
DBCC CHECKIDENT ('alerta', RESEED, 0);
DBCC CHECKIDENT ('pago', RESEED, 0);
DBCC CHECKIDENT ('detalle_factura', RESEED, 0);
DBCC CHECKIDENT ('factura', RESEED, 0);
DBCC CHECKIDENT ('consumo', RESEED, 0);
DBCC CHECKIDENT ('detalle_reserva', RESEED, 0);
DBCC CHECKIDENT ('reserva', RESEED, 0);
DBCC CHECKIDENT ('habitacion', RESEED, 0);
DBCC CHECKIDENT ('servicio_adicional', RESEED, 0);
DBCC CHECKIDENT ('vista', RESEED, 0);
DBCC CHECKIDENT ('tarifa', RESEED, 0);
DBCC CHECKIDENT ('tipo_habitacion', RESEED, 0);
DBCC CHECKIDENT ('temporada', RESEED, 0);
DBCC CHECKIDENT ('cliente', RESEED, 0);

-- ==============================================================================
-- 2. CONFIGURACIÓN DEL HOTEL
-- ==============================================================================
PRINT '2. Configurando Maestros (Temporadas, Hab, Servicios)...';

-- Temporadas (Pasado, Presente, Futuro) - Ajustadas para Nov 2025
INSERT INTO temporada (nombre, descripcion, fecha_inicio, fecha_fin) VALUES
('Temp Alta 2024-2025', 'Verano Pasado', '2024-12-01', '2025-03-31'),
('Temp Baja 2025', 'Invierno Pasado', '2025-04-01', '2025-08-31'),
('Temp Media 2025', 'Primavera Actual', '2025-09-01', '2025-11-30'),
('Temp Alta 2025-2026', 'Verano Próximo', '2025-12-01', '2026-03-31'),
('Temp Baja 2026', 'Invierno Futuro', '2026-04-01', '2026-08-31')


-- Tipos de Habitación
INSERT INTO tipo_habitacion (nombre, descripcion, capacidad) VALUES
('Standard', 'Habitación cómoda para 2', 2),
('Superior', 'Mayor espacio y confort', 3),
('Suite', 'Lujo total con jacuzzi', 4);

-- Vistas
INSERT INTO vista (nombre, descripcion) VALUES 
('Mar', 'Vista frontal al mar caribe'), 
('Jardín', 'Vista al jardin'), 
('Interna', 'Vista al interior del edificio');

-- Servicios Adicionales
INSERT INTO servicio_adicional (nombre, descripcion, costo, precio, cupo_diario_max) VALUES
('Gimnasio', 'Gimnasio premium con zona de cardio ', 5.00, 15.00, 200),
('Traslado aeropuerto', 'Charter bus para traslado desde aeropuerto hasta el hotel', 20.00, 60.00, 15),
('Cena tematica', 'Cena en restaurante 4 estrellas ambientado con tematica caribeña', 40.00, 100.00, 10),
('Excursion atardecer', 'Excursion hacia isla remota', 30.00, 80.00, 5),
('Alquiler de bicicletas', 'Alquiler de bicicletas para movilizarse dentro del resort', 10.00, 25.00, 100),
('Piscina premium','Piscina exclusiva climatizada',25,40,50);

-- Tarifas (Generación dinámica de precios por temporada)
INSERT INTO tarifa (id_tipo_habitacion, id_temporada, descripcion, precio_noche)
SELECT th.id_tipo_habitacion, t.id_temporada, 
       CONCAT(th.nombre, ' - ', t.nombre),
       CASE 
           WHEN th.nombre = 'Standard' THEN 100 + (CASE WHEN t.nombre LIKE '%Alta%' THEN 50 ELSE 0 END)
           WHEN th.nombre = 'Deluxe' THEN 150 + (CASE WHEN t.nombre LIKE '%Alta%' THEN 80 ELSE 0 END)
           WHEN th.nombre = 'Suite Presidencial' THEN 300 + (CASE WHEN t.nombre LIKE '%Alta%' THEN 150 ELSE 0 END)
           ELSE 120
       END
FROM tipo_habitacion th CROSS JOIN temporada t;

-- Habitaciones (Generar 30 habitaciones: 10 por piso)
DECLARE @piso INT = 1;
DECLARE @hab_count INT = 1;

-- Variables auxiliares para asegurar IDs válidos
DECLARE @id_tipo_random INT;
DECLARE @id_vista_random INT;

WHILE @piso <= 3
BEGIN
    SET @hab_count = 1;
    WHILE @hab_count <= 10
    BEGIN
        -- Seleccionamos un ID real existente al azar para evitar errores de FK
        SELECT TOP 1 @id_tipo_random = id_tipo_habitacion FROM tipo_habitacion ORDER BY NEWID();
        SELECT TOP 1 @id_vista_random = id_vista FROM vista ORDER BY NEWID();

        INSERT INTO habitacion (numero_habitacion, id_tipo_habitacion, id_vista, nombre, piso, estado_operativo)
        VALUES (
            CONCAT(@piso, '0', CASE WHEN @hab_count < 10 THEN '0' ELSE '' END, @hab_count), -- Ej: 1001, 1002
            @id_tipo_random, -- Usamos el ID real obtenido
            @id_vista_random, -- Usamos el ID real obtenido
            CONCAT('Hab ', @piso, '0', @hab_count),
            @piso,
            CASE WHEN (ABS(CHECKSUM(NEWID())) % 20) = 0 THEN 'FUERA_SERVICIO' ELSE 'DISPONIBLE' END
        );
        SET @hab_count = @hab_count + 1;
    END
    SET @piso = @piso + 1;
END

-- ==============================================================================
-- 3. GENERACIÓN DE CLIENTES (Datos Aleatorios)
-- ==============================================================================
PRINT '3. Creando 50 Clientes...';
DECLARE @i INT = 0;
DECLARE @nombre VARCHAR(50);
DECLARE @apellido VARCHAR(50);
DECLARE @dni VARCHAR(20);

WHILE @i < 50
BEGIN
    -- Seleccionar nombre al azar
    SELECT @nombre = CASE (ABS(CHECKSUM(NEWID())) % 10)
        WHEN 0 THEN 'Carlos' WHEN 1 THEN 'Maria' WHEN 2 THEN 'Juan' WHEN 3 THEN 'Ana' WHEN 4 THEN 'Pedro'
        WHEN 5 THEN 'Lucia' WHEN 6 THEN 'Miguel' WHEN 7 THEN 'Sofia' WHEN 8 THEN 'Diego' ELSE 'Elena' END;
    
    -- Seleccionar apellido al azar
    SELECT @apellido = CASE (ABS(CHECKSUM(NEWID())) % 10)
        WHEN 0 THEN 'Garcia' WHEN 1 THEN 'Martinez' WHEN 2 THEN 'Lopez' WHEN 3 THEN 'Rodriguez' WHEN 4 THEN 'Perez'
        WHEN 5 THEN 'Fernandez' WHEN 6 THEN 'Gonzalez' WHEN 7 THEN 'Sanchez' WHEN 8 THEN 'Ramirez' ELSE 'Torres' END;

    SET @dni = CAST(ABS(CHECKSUM(NEWID())) % 90000000 + 10000000 AS VARCHAR);
    
    BEGIN TRY
        INSERT INTO cliente (nombre, apellido, dni, email, telefono, estado, fecha_nacimiento)
        VALUES (
            @nombre, 
            @apellido, 
            @dni, 
            LOWER(CONCAT(@nombre, '.', @apellido, @i, '@gmail.com')), -- Email único y válido
            CONCAT('555-', 1000 + @i),
            'ACTIVO',
            DATEADD(YEAR, - (20 + (ABS(CHECKSUM(NEWID())) % 30)), GETDATE()) -- Entre 20 y 50 años
        );
    END TRY
    BEGIN CATCH
        -- Ignorar duplicados si el azar falla
    END CATCH

    SET @i = @i + 1;
END

-- ==============================================================================
-- 4. GENERACIÓN DE RESERVAS Y TRANSACCIONES
-- ==============================================================================
PRINT '4. Generando Historial de Reservas, Consumos, Facturas y Pagos...';

DECLARE @k INT = 0;
DECLARE @id_cliente INT;
DECLARE @id_habitacion INT;
DECLARE @fecha_inicio DATETIME;
DECLARE @noches INT;
DECLARE @total_reserva DECIMAL(10,2);
DECLARE @precio_noche DECIMAL(10,2);
DECLARE @id_reserva INT;
DECLARE @estado_reserva VARCHAR(20);

-- Generar 100 reservas mezcladas (Pasadas, Actuales, Futuras)
WHILE @k < 100
BEGIN
    -- Cliente Aleatorio
    SELECT TOP 1 @id_cliente = id_cliente FROM cliente ORDER BY NEWID();
    -- Habitación Aleatoria
    SELECT TOP 1 @id_habitacion = id_habitacion FROM habitacion WHERE estado_operativo = 'DISPONIBLE' ORDER BY NEWID();
    
    -- Fecha Aleatoria (Entre hace 6 meses y dentro de 3 meses)
    SET @fecha_inicio = DATEADD(DAY, (ABS(CHECKSUM(NEWID())) % 270) - 180, GETDATE());
    SET @noches = (ABS(CHECKSUM(NEWID())) % 7) + 2; -- 2 a 9 noches
    
    -- Determinar Estado basado en la fecha
    IF @fecha_inicio < DATEADD(DAY, -@noches, GETDATE()) SET @estado_reserva = 'COMPLETADA'; -- Ya terminó
    ELSE IF @fecha_inicio <= GETDATE() AND DATEADD(DAY, @noches, @fecha_inicio) >= GETDATE() SET @estado_reserva = 'EN_CURSO'; -- Ocurriendo ahora
    ELSE SET @estado_reserva = 'CONFIRMADA'; -- Futura

    -- Obtener Precio (Simplificado: tomamos el precio actual de la habitación para no complicar el script con logica de temporadas)
    -- En un seed real perfecto buscaríamos la tarifa exacta de la fecha, aquí usamos un promedio para velocidad
    SELECT TOP 1 @precio_noche = t.precio_noche 
    FROM tarifa t 
    JOIN habitacion h ON h.id_tipo_habitacion = t.id_tipo_habitacion 
    WHERE h.id_habitacion = @id_habitacion;

    SET @total_reserva = @precio_noche * @noches;

    BEGIN TRY
        -- Insertar Reserva (Directo para evitar validaciones complejas del SP en seeding masivo, pero manteniendo integridad)
        -- Verificamos solapamiento simple antes de insertar
        IF NOT EXISTS (
            SELECT 1 FROM detalle_reserva 
            WHERE id_habitacion = @id_habitacion 
            AND (
                (@fecha_inicio BETWEEN fecha_checkin AND fecha_checkout) OR 
                (DATEADD(DAY, @noches, @fecha_inicio) BETWEEN fecha_checkin AND fecha_checkout)
            )
        )
        BEGIN
            INSERT INTO reserva (id_cliente, estado_reserva, total, fecha_checkin, fecha_checkout)
            VALUES (@id_cliente, @estado_reserva, @total_reserva, @fecha_inicio, DATEADD(DAY, @noches, @fecha_inicio));
            
            SET @id_reserva = SCOPE_IDENTITY();

            INSERT INTO detalle_reserva (id_reserva, id_habitacion, precio_noche, fecha_checkin, fecha_checkout, cant_noches)
            VALUES (@id_reserva, @id_habitacion, @precio_noche, @fecha_inicio, DATEADD(DAY, @noches, @fecha_inicio), @noches);

            -- -------------------------------------------------------
            -- LOGICA FINANCIERA (Solo para COMPLETADA o EN_CURSO)
            -- -------------------------------------------------------
            IF @estado_reserva IN ('COMPLETADA', 'EN_CURSO')
            BEGIN
                -- 1. Generar Consumos Adicionales (50% probabilidad)
                IF (ABS(CHECKSUM(NEWID())) % 2) = 0
                BEGIN
                    DECLARE @id_serv INT;
                    DECLARE @costo_serv DECIMAL(10,2);
                    DECLARE @precio_serv DECIMAL(10,2);
                    
                    SELECT TOP 1 @id_serv = id_servicio_adicional, @precio_serv = precio FROM servicio_adicional ORDER BY NEWID();
                    
                    INSERT INTO consumo (id_cliente, id_reserva, id_servicio_adicional, cantidad, precio_unitario, fecha_servicio, subtotal)
                    VALUES (@id_cliente, @id_reserva, @id_serv, 2, @precio_serv, DATEADD(DAY, 1, @fecha_inicio), @precio_serv * 2);
                    
                    -- Actualizar total reserva
                    UPDATE reserva SET total = total + (@precio_serv * 2) WHERE id_reserva = @id_reserva;
                    SET @total_reserva = @total_reserva + (@precio_serv * 2);
                END

                -- 2. Generar Factura y Pago (Solo si está completada o en curso pagada)
                INSERT INTO factura (id_cliente, id_reserva, numero_factura, tipo_comprobante, concepto, subtotal, impuestos, total, estado)
                VALUES (
                    @id_cliente, 
                    @id_reserva, 
                    CONCAT('F-', YEAR(GETDATE()), '-', 10000 + @id_reserva), 
                    'FACTURA', 
                    'Hospedaje y Servicios', 
                    @total_reserva * 0.8, -- Subtotal fake
                    @total_reserva * 0.2, -- Impuesto fake
                    @total_reserva, 
                    'EMITIDA'
                );
                
                DECLARE @id_factura INT = SCOPE_IDENTITY();

                -- Detalle de factura
                INSERT INTO detalle_factura (id_factura, concepto, cantidad, precio_unitario, subtotal)
                VALUES (@id_factura, 'Alojamiento', @noches, @precio_noche, @precio_noche * @noches);

                -- Pago Total
                INSERT INTO pago (id_reserva, id_factura, tipo_pago, metodo_pago, monto, estado, referencia, concepto)
                VALUES (
                    @id_reserva, 
                    @id_factura, 
                    'SALDO', 
                    CASE (ABS(CHECKSUM(NEWID())) % 3) WHEN 0 THEN 'TARJETA_CREDITO' WHEN 1 THEN 'EFECTIVO' ELSE 'TRANSFERENCIA' END, 
                    @total_reserva, 
                    'APROBADO', 
                    CONCAT('TXN-', NEWID()), 
                    'Pago total check-out'
                );
            END
        END
    END TRY
    BEGIN CATCH
        -- Si falla por overlap o constraint, continuamos al siguiente loop
    END CATCH

    SET @k = @k + 1;
END

-- ==============================================================================
-- 5. GENERACIÓN DE ALERTAS (Para demostrar la vista de habitaciones repetidas)
-- ==============================================================================
PRINT '5. Generando Alertas de Repetición...';

-- Simulamos que algunos clientes intentaron reservar la misma habitación varias veces
DECLARE @alert_count INT = 0;
DECLARE @cliente_alerta INT;
DECLARE @hab_alerta INT;
DECLARE @reserva_alerta INT;
DECLARE @fecha_checkin_alerta DATETIME;

-- Generamos 15 alertas de repetición
WHILE @alert_count < 15
BEGIN
    -- Seleccionar una reserva al azar
    SELECT TOP 1 
        @reserva_alerta = r.id_reserva,
        @cliente_alerta = r.id_cliente,
        @fecha_checkin_alerta = r.fecha_checkin
    FROM reserva r
    WHERE r.estado_reserva IN ('CONFIRMADA', 'EN_CURSO', 'COMPLETADA')
    ORDER BY NEWID();
    
    -- Obtener la habitación de esa reserva
    SELECT TOP 1 @hab_alerta = id_habitacion 
    FROM detalle_reserva 
    WHERE id_reserva = @reserva_alerta;
    
    -- Generar entre 2 y 5 intentos de alerta para la misma combinación
    DECLARE @intentos INT = (ABS(CHECKSUM(NEWID())) % 4) + 2; -- Entre 2 y 5
    DECLARE @intento_actual INT = 0;
    
    WHILE @intento_actual < @intentos
    BEGIN
        BEGIN TRY
            -- Insertar alerta con delay simulado entre intentos
            INSERT INTO alerta (id_cliente, id_habitacion, tipo, descripcion, id_reserva, creado_por, fecha_creacion)
            VALUES (
                @cliente_alerta,
                @hab_alerta,
                'REPETICION',
                CONCAT('Cliente intentó reservar habitación ', @hab_alerta, ' para fecha ', 
                       CONVERT(VARCHAR(10), @fecha_checkin_alerta, 120), ' múltiples veces'),
                @reserva_alerta,
                'SISTEMA_RESERVAS',
                DATEADD(MINUTE, -(@intentos - @intento_actual) * 5, GETDATE()) -- Simular intentos espaciados
            );
        END TRY
        BEGIN CATCH
            -- Ignorar errores y continuar
        END CATCH
        
        SET @intento_actual = @intento_actual + 1;
    END
    
    SET @alert_count = @alert_count + 1;
END

-- Agregar algunas alertas adicionales de otros tipos para variedad
INSERT INTO alerta (id_habitacion, tipo, descripcion, creado_por) VALUES
((SELECT TOP 1 id_habitacion FROM habitacion WHERE estado_operativo = 'FUERA_SERVICIO' ORDER BY NEWID()), 
 'MANTENIMIENTO', 'Habitación requiere mantenimiento preventivo de aire acondicionado', 'STAFF_MANTENIMIENTO');

INSERT INTO alerta (id_habitacion, tipo, descripcion, creado_por) VALUES
((SELECT TOP 1 id_habitacion FROM habitacion ORDER BY NEWID()), 
 'ADVERTENCIA', 'Revisar sistema de agua caliente en esta habitación', 'STAFF_RECEPCION');

PRINT '==========================================================';
PRINT ' SEEDING FINALIZADO CON ÉXITO ';
PRINT '==========================================================';
GO

-- ==============================================================================
-- QUERIES PARA LA PRESENTACIÓN (CHEAT SHEET)
-- Copia esto para tenerlo a mano durante la demo
-- ==============================================================================

PRINT ''
PRINT 'DATOS GENERADOS:'
PRINT '----------------'
SELECT 'Clientes' as Tabla, COUNT(*) as Cantidad FROM cliente
UNION ALL SELECT 'Habitaciones', COUNT(*) FROM habitacion
UNION ALL SELECT 'Reservas Totales', COUNT(*) FROM reserva
UNION ALL SELECT 'Facturas Emitidas', COUNT(*) FROM factura
UNION ALL SELECT 'Pagos Registrados', COUNT(*) FROM pago;

PRINT ''
PRINT 'EJEMPLO: TOP 5 CLIENTES QUE MAS GASTARON (Para mostrar queries complejos):'
SELECT TOP 5 
    c.nombre, c.apellido, COUNT(r.id_reserva) as reservas, SUM(r.total) as total_gastado
FROM cliente c
JOIN reserva r ON c.id_cliente = r.id_cliente
GROUP BY c.nombre, c.apellido
ORDER BY total_gastado DESC;

PRINT ''
PRINT 'ALERTAS POR TIPO:'
SELECT tipo, COUNT(*) as cantidad
FROM alerta
GROUP BY tipo
ORDER BY cantidad DESC;

PRINT ''
PRINT 'VISTA: HABITACIONES CON INTENTOS DE RESERVA REPETIDOS:'
SELECT * FROM dbo.vw_habitaciones_repetidas
ORDER BY cantidad_intentos DESC;
