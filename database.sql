-- Crear la base de datos si no existe
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'BahiaSerenaDB')
BEGIN
	CREATE DATABASE BahiaSerenaDB;
END
GO

-- Usar la base de datos creada
USE BahiaSerenaDB;
GO

-- Crear las tablas de la base de datos
CREATE TABLE temporada (
    id_temporada INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(50),
    descripcion VARCHAR(255),
    fecha_inicio  DATETIME,
    fecha_fin DATETIME,
    creado_por VARCHAR(100) DEFAULT SYSTEM_USER,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    modificado_por VARCHAR(100),
    fecha_modificacion DATETIME,
    eliminado_por VARCHAR(100),
    fecha_eliminacion DATETIME,
    CHECK (fecha_fin > fecha_inicio)
);

CREATE TABLE tipo_habitacion(
    id_tipo_habitacion INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(50),
    descripcion VARCHAR(255),
    capacidad INT,
    creado_por VARCHAR(100) DEFAULT SYSTEM_USER,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    modificado_por VARCHAR(100),
    fecha_modificacion DATETIME,
    eliminado_por VARCHAR(100),
    fecha_eliminacion DATETIME,
    CHECK (capacidad > 0)
);

CREATE TABLE tarifa(
    id_tarifa INT PRIMARY KEY IDENTITY(1,1),
    id_tipo_habitacion INT,
    id_temporada INT,
    descripcion VARCHAR(255),
    precio_noche DECIMAL(10,2),
    creado_por VARCHAR(100) DEFAULT SYSTEM_USER,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    modificado_por VARCHAR(100),
    fecha_modificacion DATETIME,
    eliminado_por VARCHAR(100),
    fecha_eliminacion DATETIME,
    CHECK (precio_noche >= 0),
    FOREIGN KEY (id_tipo_habitacion) REFERENCES tipo_habitacion(id_tipo_habitacion),
    FOREIGN KEY (id_temporada) REFERENCES temporada(id_temporada)
);

CREATE TABLE vista(
    id_vista INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(50),
    descripcion VARCHAR(255),
    creado_por VARCHAR(100) DEFAULT SYSTEM_USER,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    modificado_por VARCHAR(100),
    fecha_modificacion DATETIME,
    eliminado_por VARCHAR(100),
    fecha_eliminacion DATETIME
);

CREATE TABLE habitacion(
    id_habitacion INT PRIMARY KEY IDENTITY(1,1),
    numero_habitacion VARCHAR(10) UNIQUE,
    id_tipo_habitacion INT,
    id_vista INT,
    nombre VARCHAR(50),
    descripcion VARCHAR(255),
    piso INT,
    estado_operativo VARCHAR(20) DEFAULT 'DISPONIBLE', -- DISPONIBLE, FUERA_SERVICIO, INACTIVA
    creado_por VARCHAR(100) DEFAULT SYSTEM_USER,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    modificado_por VARCHAR(100),
    fecha_modificacion DATETIME,
    eliminado_por VARCHAR(100),
    fecha_eliminacion DATETIME,
    CHECK (piso >= 0),
    CHECK (estado_operativo IN ('DISPONIBLE', 'FUERA_SERVICIO', 'INACTIVA', 'OCUPADA')),
    FOREIGN KEY (id_tipo_habitacion) REFERENCES tipo_habitacion(id_tipo_habitacion),
    FOREIGN KEY (id_vista) REFERENCES vista(id_vista)
);

CREATE TABLE cliente(
    id_cliente INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(50),
    apellido VARCHAR(50),
    dni VARCHAR(20) UNIQUE,
    email VARCHAR(100) UNIQUE,
    telefono VARCHAR(20),
    estado VARCHAR(20) DEFAULT 'ACTIVO', -- ACTIVO, INACTIVO
    fecha_nacimiento DATETIME,
    creado_por VARCHAR(100) DEFAULT SYSTEM_USER,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    modificado_por VARCHAR(100),
    fecha_modificacion DATETIME,
    eliminado_por VARCHAR(100),
    fecha_eliminacion DATETIME,
    CHECK ((YEAR(GETDATE()) - YEAR(fecha_nacimiento)) >= 18 ),
    CHECK (
        email LIKE '%_@_%.__%' AND                          -- Formato básico: algo@algo.algo
        email NOT LIKE '%@%@%' AND                          -- No permite múltiples @
        email NOT LIKE '@%' AND                             -- No empieza con @
        email NOT LIKE '%@' AND                             -- No termina con @
        email NOT LIKE '%.@%' AND                           -- No permite .@
        email NOT LIKE '%@.%' AND                           -- No permite @.
        email NOT LIKE '% %' AND                            -- No permite espacios
        email NOT LIKE '%..' AND                            -- No permite puntos consecutivos
        LEN(email) >= 6 AND                                 -- Mínimo 6 caracteres (a@b.co)
        LEN(email) <= 100 AND                               -- Máximo 100 caracteres
        CHARINDEX('.', SUBSTRING(email, CHARINDEX('@', email), LEN(email))) > 0 AND  -- Debe haber . después de @
        LEN(SUBSTRING(email, CHARINDEX('@', email) + 1, LEN(email))) >= 4  -- Mínimo 4 chars después de @ (x.co)
    ),
    CHECK (estado IN ('ACTIVO', 'INACTIVO'))
);


-- VALIDACIÓN MEJORADA DE EMAIL:
-- ✓ Formato básico: usuario@dominio.extension
-- ✓ Un solo símbolo @
-- ✓ No comienza ni termina con @
-- ✓ No permite espacios
-- ✓ No permite puntos consecutivos (..)
-- ✓ No permite .@ o @.
-- ✓ Mínimo 6 caracteres (a@b.co)
-- ✓ Máximo 100 caracteres
-- ✓ Debe haber al menos un punto después de @
-- ✓ Al menos 4 caracteres después de @ (para dominio.ext)
--
-- ✓ Válidos: juan@gmail.com, maria.lopez@empresa.com.ar, test123@mail.co
-- ✗ Inválidos: @mail.com, user@, user@@mail.com, user@mail, a@b.c (muy corto después de @)

CREATE TABLE reserva(
    id_reserva INT PRIMARY KEY IDENTITY(1,1),
    id_cliente INT,
    estado_reserva VARCHAR(20) DEFAULT 'PENDIENTE', -- PENDIENTE, CONFIRMADA, EN_CURSO, COMPLETADA, CANCELADA
    total DECIMAL(10,2),
    fecha_checkin DATETIME,
    fecha_checkout DATETIME,
    creado_por VARCHAR(100) DEFAULT SYSTEM_USER,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    modificado_por VARCHAR(100),
    fecha_modificacion DATETIME,
    eliminado_por VARCHAR(100),
    fecha_eliminacion DATETIME,
    CHECK (estado_reserva IN ('PENDIENTE', 'CONFIRMADA', 'EN_CURSO', 'COMPLETADA', 'CANCELADA')),
    CHECK (fecha_checkout > fecha_checkin),
    CHECK (total >= 0),
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
);


CREATE TABLE detalle_reserva(
    id_detalle_reserva INT PRIMARY KEY IDENTITY(1,1),
    id_reserva INT,
    id_habitacion INT,
    precio_noche DECIMAL(10,2), --trazabilidad de costos
    fecha_checkin DATETIME,
    fecha_checkout DATETIME,
    cant_noches INT, --trazabilidad de costos
    creado_por VARCHAR(100) DEFAULT SYSTEM_USER,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    modificado_por VARCHAR(100),
    fecha_modificacion DATETIME,
    eliminado_por VARCHAR(100),
    fecha_eliminacion DATETIME,
    CHECK (fecha_checkout > fecha_checkin),
    CHECK (precio_noche >= 0),
    CHECK (cant_noches > 0),
    FOREIGN KEY (id_reserva) REFERENCES reserva(id_reserva),
    FOREIGN KEY (id_habitacion) REFERENCES habitacion(id_habitacion)
);


CREATE TABLE servicio_adicional(
    id_servicio_adicional INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(50),
    descripcion VARCHAR(255),
    costo DECIMAL(10,2), -- Costo del servicio para calcular margen (Ejercicio 1)
    precio DECIMAL(10,2),
    cupo_diario_max INT, -- Cupo máximo por día (ej: Spa = 50 cupos/día)
    creado_por VARCHAR(100) DEFAULT SYSTEM_USER,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    modificado_por VARCHAR(100),
    fecha_modificacion DATETIME,
    eliminado_por VARCHAR(100),
    fecha_eliminacion DATETIME,
    CHECK (costo >= 0),
    CHECK (precio >= 0),
    CHECK (cupo_diario_max >= 0)
);

CREATE TABLE consumo(
    id_consumo INT PRIMARY KEY IDENTITY(1,1),
    id_cliente INT,
    id_reserva INT,
    id_servicio_adicional INT,
    cantidad INT,
    precio_unitario DECIMAL(10,2), -- trazabilidad de costos
    fecha_servicio DATETIME,
    subtotal DECIMAL(10,2), -- trazabilidad de costos
    creado_por VARCHAR(100) DEFAULT SYSTEM_USER,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    modificado_por VARCHAR(100),
    fecha_modificacion DATETIME,
    eliminado_por VARCHAR(100),
    fecha_eliminacion DATETIME,
    CHECK (cantidad > 0),
    CHECK (precio_unitario >= 0),
    CHECK (subtotal >= 0),
    CHECK (id_cliente IS NOT NULL OR id_reserva IS NOT NULL),
    FOREIGN KEY (id_reserva) REFERENCES reserva(id_reserva),
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
    FOREIGN KEY (id_servicio_adicional) REFERENCES servicio_adicional(id_servicio_adicional)
);

CREATE TABLE factura(
    id_factura INT PRIMARY KEY IDENTITY(1,1),
    id_cliente INT, -- Factura al cliente, no necesariamente a una reserva
    id_reserva INT NULL, -- Puede ser NULL si es solo servicios adicionales
    numero_factura VARCHAR(50) UNIQUE NOT NULL, -- Ej: F-2025-00001
    tipo_comprobante VARCHAR(20), -- FACTURA, BOLETA, TICKET
    concepto VARCHAR(255), -- Ej: "Reserva habitación", "Servicios adicionales", "Cena temática"
    subtotal DECIMAL(10,2),
    impuestos DECIMAL(10,2),
    total DECIMAL(10,2),
    estado VARCHAR(20), -- EMITIDA, ANULADA
    fecha_emision DATETIME DEFAULT GETDATE(),
    creado_por VARCHAR(100) DEFAULT SYSTEM_USER,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    modificado_por VARCHAR(100),
    fecha_modificacion DATETIME,
    eliminado_por VARCHAR(100),
    fecha_eliminacion DATETIME,
    CHECK (tipo_comprobante IN ('FACTURA', 'BOLETA', 'TICKET')),
    CHECK (estado IN ('EMITIDA', 'ANULADA')),
    CHECK (subtotal >= 0),
    CHECK (impuestos >= 0),
    CHECK (total >= 0),
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
    FOREIGN KEY (id_reserva) REFERENCES reserva(id_reserva)
);

CREATE TABLE detalle_factura(
    id_detalle_factura INT PRIMARY KEY IDENTITY(1,1),
    id_factura INT,
    concepto VARCHAR(255), -- Ej: "Habitación Suite - 3 noches", "Spa - Masaje relajante"
    cantidad INT,
    precio_unitario DECIMAL(10,2),
    subtotal DECIMAL(10,2),
    -- Referencias opcionales para trazabilidad
    id_detalle_reserva INT NULL, -- Si es una habitación
    id_consumo INT NULL, -- Si es un servicio adicional
    creado_por VARCHAR(100) DEFAULT SYSTEM_USER,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    modificado_por VARCHAR(100),
    fecha_modificacion DATETIME,
    eliminado_por VARCHAR(100),
    fecha_eliminacion DATETIME,
    CHECK (cantidad > 0),
    CHECK (precio_unitario >= 0),
    CHECK (subtotal >= 0),
    FOREIGN KEY (id_factura) REFERENCES factura(id_factura),
    FOREIGN KEY (id_detalle_reserva) REFERENCES detalle_reserva(id_detalle_reserva),
    FOREIGN KEY (id_consumo) REFERENCES consumo(id_consumo)
);

CREATE TABLE pago(
    id_pago INT PRIMARY KEY IDENTITY(1,1),
    id_reserva INT NULL, -- NULL para clientes walk-in sin reserva
    id_factura INT NULL, -- NULL si es pago anticipado (seña), luego se vincula
    tipo_pago VARCHAR(20), -- SEÑA, ANTICIPO, SALDO, CONSUMO
    metodo_pago VARCHAR(20),
    monto DECIMAL(10,2),
    estado VARCHAR(20), -- APROBADO, RECHAZADO, PENDIENTE
    referencia VARCHAR(100), -- Número de transacción, cheque, etc.
    concepto VARCHAR(255), -- Ej: "Seña reserva habitación 201", "Saldo check-in"
    fecha_pago DATETIME DEFAULT GETDATE(),
    creado_por VARCHAR(100) DEFAULT SYSTEM_USER,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    modificado_por VARCHAR(100),
    fecha_modificacion DATETIME,
    eliminado_por VARCHAR(100),
    fecha_eliminacion DATETIME,
    CHECK (tipo_pago IN ('SEÑA', 'ANTICIPO', 'SALDO', 'CONSUMO')),
    CHECK (metodo_pago IN ('TARJETA_CREDITO', 'TARJETA_DEBITO', 'EFECTIVO', 'TRANSFERENCIA')),
    CHECK (estado IN ('APROBADO', 'RECHAZADO', 'PENDIENTE')),
    CHECK (monto > 0),
    CHECK (id_reserva IS NOT NULL OR id_factura IS NOT NULL), -- Al menos uno debe existir
    FOREIGN KEY (id_reserva) REFERENCES reserva(id_reserva),
    FOREIGN KEY (id_factura) REFERENCES factura(id_factura)
);

CREATE TABLE alerta(
    id_alerta INT PRIMARY KEY IDENTITY(1,1),
    tipo VARCHAR(20), -- REPETICION, ERROR, MANTENIMIENTO, ADVERTENCIA
    descripcion VARCHAR(500),
    id_cliente INT NULL,
    id_reserva INT NULL,
    id_habitacion INT NULL,
    creado_por VARCHAR(100) DEFAULT SYSTEM_USER,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    modificado_por VARCHAR(100),
    fecha_modificacion DATETIME,
    eliminado_por VARCHAR(100),
    fecha_eliminacion DATETIME,
    CHECK (tipo IN ('REPETICION', 'ERROR', 'MANTENIMIENTO', 'ADVERTENCIA')),
    FOREIGN KEY (id_reserva) REFERENCES reserva(id_reserva),
    FOREIGN KEY (id_habitacion) REFERENCES habitacion(id_habitacion),
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
);
