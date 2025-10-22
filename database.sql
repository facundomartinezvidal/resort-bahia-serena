CREATE TABLE vista(
    id_vista INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(50),
);

CREATE TABLE tipo_habitacion(
    id_tipo_habitacion INT PRIMARY KEY IDENTITY (1,1),
    nombre VARCHAR(50),
    capacidad INT,
    CHECK (capacidad > 0)
);

CREATE TABLE temporada (
    id_temporada INT PRIMARY KEY IDENTITY (1,1),
    nombre VARCHAR(50),
    fecha_inicio  DATETIME,
    fecha_fin DATETIME,
    CHECK (fecha_fin > fecha_inicio)
);

CREATE TABLE habitacion(
    id_habitacion INT PRIMARY KEY IDENTITY (1,1),
    piso INT,
    CHECK (piso >= 0),
    id_tipo_habitacion INT,
    id_vista INT,
    precio_base DECIMAL(10,2),
    estado_operativo VARCHAR(20),
    CHECK (estado_operativo IN ('DISPONIBLE', 'FUERA_SERVICIO', 'INACTIVA')),
    FOREIGN KEY (id_tipo_habitacion) REFERENCES tipo_habitacion(id_tipo_habitacion),
    FOREIGN KEY (id_vista) REFERENCES vista(id_vista)
);

CREATE TABLE tipo_habitacion(
    id_tipo_habitacion INT PRIMARY KEY IDENTITY (1,1),
    nombre VARCHAR(50),
    capacidad INT,
    CHECK (capacidad > 0),
);

CREATE TABLE tarifa(
    id_tarifa INT PRIMARY KEY IDENTITY (1,1),
    id_tipo_habitacion INT,
    id_temporada INT,
    precio_noche DECIMAL(10,2),
    CHECK (precio_noche >= 0),
    FOREIGN KEY (id_tipo_habitacion) REFERENCES tipo_habitacion(id_tipo_habitacion),
    FOREIGN KEY (id_temporada) REFERENCES temporada(id_temporada)

);



CREATE TABLE cliente(
    id_cliente INT PRIMARY KEY IDENTITY (1,1),
    nombre VARCHAR(50),
    apellido VARCHAR(50),
    dni VARCHAR(20) UNIQUE,
    email VARCHAR(100) UNIQUE,
    CHECK (email LIKE '%_@__%.__%'),
    telefono VARCHAR(20),
    estado VARCHAR(20),
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
    fecha_check_in DATETIME,
    fecha_check_out DATETIME,
    CHECK (fecha_check_out > fecha_check_in),
    estado VARCHAR(20),
    CHECK (estado IN ('CONFIRMADA', 'CANCELADA', 'COMPLETADA')),
);





