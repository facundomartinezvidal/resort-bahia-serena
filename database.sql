USE master

CREATE TABLE temporada (
    id_temporada INT PRIMARY KEY IDENTITY (1,1),
    nombre VARCHAR(50),
    descripcion VARCHAR(255),
    fecha_inicio  DATETIME,
    fecha_fin DATETIME,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_modificacion DATETIME,
    fecha_eliminacion DATETIME,
    CHECK (fecha_fin > fecha_inicio)
);

CREATE TABLE tipo_habitacion(
    id_tipo_habitacion INT PRIMARY KEY IDENTITY (1,1),
    nombre VARCHAR(50),
    descripcion VARCHAR(255),
    capacidad INT,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_modificacion DATETIME,
    fecha_eliminacion DATETIME,
    CHECK (capacidad > 0)
);

CREATE TABLE tarifa(
    id_tarifa INT PRIMARY KEY IDENTITY (1,1),
    id_tipo_habitacion INT,
    id_temporada INT,
    descripcion VARCHAR(255),
    precio_noche DECIMAL(10,2),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_modificacion DATETIME,
    fecha_eliminacion DATETIME,
    CHECK (precio_noche >= 0),
    FOREIGN KEY (id_tipo_habitacion) REFERENCES tipo_habitacion(id_tipo_habitacion),
    FOREIGN KEY (id_temporada) REFERENCES temporada(id_temporada)
);

CREATE TABLE vista(
    id_vista INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(50),
    descripcion VARCHAR(255),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_modificacion DATETIME,
    fecha_eliminacion DATETIME
);

CREATE TABLE habitacion(
    id_habitacion INT PRIMARY KEY IDENTITY (1,1),
    id_tipo_habitacion INT,
    id_vista INT,
    nombre VARCHAR(50),
    descripcion VARCHAR(255),
    piso INT,
    estado_operativo VARCHAR(20),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_modificacion DATETIME,
    fecha_eliminacion DATETIME,
    CHECK (piso >= 0),
    CHECK (estado_operativo IN ('DISPONIBLE', 'FUERA_SERVICIO', 'INACTIVA')),
    FOREIGN KEY (id_tipo_habitacion) REFERENCES tipo_habitacion(id_tipo_habitacion),
    FOREIGN KEY (id_vista) REFERENCES vista(id_vista)
);

CREATE TABLE cliente(
    id_cliente INT PRIMARY KEY IDENTITY (1,1),
    nombre VARCHAR(50),
    apellido VARCHAR(50),
    dni VARCHAR(20) UNIQUE,
    email VARCHAR(100) UNIQUE,
    telefono VARCHAR(20),
    estado VARCHAR(20),
    fecha_nacimiento DATETIME,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_modificacion DATETIME,
    fecha_eliminacion DATETIME,
    CHECK ((YEAR(GETDATE()) - YEAR(fecha_nacimiento)) >= 18 ),
    CHECK (email LIKE '%_@__%.__%'),
    CHECK (estado IN ('ACTIVO', 'INACTIVO'))
);

--Desglose del patrón:
-- `%_@__%.__%`
-- | `%` | Cero o más caracteres de cualquier tipo | "abc", "x", "" |
-- | `_` | Exactamente **UN** carácter (cualquiera) | "a", "5", "@" |
-- | `@` | El carácter arroba literal | @ |
-- | `.` | El punto literal | . |

-- %_@__%.__%
-- │ │ │ │ │ │
-- │ │ │ │ │ └── Al menos 2 caracteres después del punto (ej: "com", "ar")
-- │ │ │ │ └──── Un punto literal
-- │ │ │ └────── Al menos 2 caracteres antes del punto (ej: "gmail", "hotmail")
-- │ │ └──────── Una arroba @
-- │ └────────── Al menos 1 carácter antes de la @ (parte del nombre)
-- └──────────── Cero o más caracteres al inicio

CREATE TABLE reserva(
    id_reserva INT PRIMARY KEY IDENTITY (1,1),
    id_cliente INT,
    estado_reserva VARCHAR(20),
    metodo_pago VARCHAR(20),
    subtotal DECIMAL(10,2),
    impuestos DECIMAL(10,2),
    total DECIMAL(10,2),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_modificacion DATETIME,
    fecha_eliminacion DATETIME,
    CHECK (estado_reserva IN ('CONFIRMADA', 'CANCELADA', 'COMPLETADA')),
    CHECK (metodo_pago IN ('TARJETA_CREDITO', 'TARJETA_DEBITO', 'EFECTIVO', 'TRANSFERENCIA')),
    CHECK (subtotal >= 0),
    CHECK (impuestos >= 0),
    CHECK (total >= 0),
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
);

CREATE TABLE detalle_reserva(
    id_detalle_reserva INT PRIMARY KEY IDENTITY (1,1),
    id_reserva INT,
    id_habitacion INT,
    precio_noche DECIMAL(10,2),
    fecha_checkin DATETIME,
    fecha_checkout DATETIME,
    cant_noches INT,
    subtotal DECIMAL(10,2),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_modificacion DATETIME,
    fecha_eliminacion DATETIME,
    CHECK (fecha_checkout > fecha_checkin),
    CHECK (precio_noche >= 0),
    CHECK (cant_noches > 0),
    CHECK (subtotal >= 0),
    FOREIGN KEY (id_reserva) REFERENCES reserva(id_reserva),
    FOREIGN KEY (id_habitacion) REFERENCES habitacion(id_habitacion)
);

CREATE TABLE factura(
    id_factura INT PRIMARY KEY IDENTITY (1,1),
    id_reserva INT,
    metodo_pago VARCHAR(20),
    estado_pago VARCHAR(20),
    subtotal DECIMAL(10,2),
    impuestos DECIMAL(10,2),
    total DECIMAL(10,2),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_modificacion DATETIME,
    fecha_eliminacion DATETIME,
    CHECK (subtotal >= 0),
    CHECK (impuestos >= 0),
    CHECK (total >= 0),
    CHECK (metodo_pago IN ('TARJETA_CREDITO', 'TARJETA_DEBITO', 'EFECTIVO', 'TRANSFERENCIA')),
    CHECK (estado_pago IN ('PENDIENTE', 'PAGADO', 'CANCELADO')),
    FOREIGN KEY (id_reserva) REFERENCES reserva(id_reserva)
);


CREATE TABLE servicio_adicional(
    id_servicio_adicional INT PRIMARY KEY IDENTITY (1,1),
    nombre VARCHAR(50),
    descripcion VARCHAR(255),
    precio DECIMAL(10,2),
    cupo_diario_max INT,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_modificacion DATETIME,
    fecha_eliminacion DATETIME,
    CHECK (precio >= 0),
    CHECK (cupo_diario_max >= 0)
);

CREATE TABLE cupos_dia(
    id_cupos_dia INT PRIMARY KEY IDENTITY (1,1),
    id_servicio_adicional INT,
    cupo_disponible INT,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_modificacion DATETIME,
    fecha_eliminacion DATETIME,
    CHECK (cupo_disponible >= 0),
    FOREIGN KEY (id_servicio_adicional) REFERENCES servicio_adicional(id_servicio_adicional)
)

CREATE TABLE detalle_factura(
    id_detalle_factura INT PRIMARY KEY IDENTITY (1,1),
    id_factura INT,
    descripcion VARCHAR(255),
    cantidad INT,
    precio_unitario DECIMAL(10,2),
    subtotal DECIMAL(10,2),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_modificacion DATETIME,
    fecha_eliminacion DATETIME,
    CHECK (cantidad > 0),
    CHECK (precio_unitario >= 0),
    CHECK (subtotal >= 0),
    FOREIGN KEY (id_factura) REFERENCES factura(id_factura),
    FOREIGN KEY (id_detalle_factura) REFERENCES servicio_adicional(id_servicio_adicional)
);

CREATE TABLE log(
    id_alerta INT PRIMARY KEY IDENTITY (1,1),
    id_habitacion INT,
    id_cliente INT,
    id_reserva INT,
    tipo VARCHAR(50),
    descripcion VARCHAR(255),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_modificacion DATETIME,
    fecha_eliminacion DATETIME,
    CHECK (tipo IN ('MANTENIMIENTO', 'REPETICION','ERROR', 'OTRO')),
    FOREIGN KEY (id_habitacion) REFERENCES habitacion(id_habitacion),
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
    FOREIGN KEY (id_reserva) REFERENCES reserva(id_reserva)
);
