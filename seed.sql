

-- Alta de Temporadas
INSERT INTO temporada (nombre, descripcion, fecha_inicio, fecha_fin)
VALUES ('ALTA', 'Temporada alta de verano', '2024-12-01', '2025-02-28');

INSERT INTO temporada (nombre, descripcion, fecha_inicio, fecha_fin)
VALUES ('MEDIA', 'Temporada media de primavera y otoño', '2025-03-01', '2025-05-31');

INSERT INTO temporada (nombre, descripcion, fecha_inicio, fecha_fin)
VALUES ('BAJA', 'Temporada baja de invierno', '2025-06-01', '2025-11-30');

INSERT INTO temporada (nombre, descripcion, fecha_inicio, fecha_fin)
VALUES ('ALTA', 'Temporada alta de verano 2026', '2025-12-01', '2026-02-28');

-- Tipo de Habitaciones
INSERT INTO tipo_habitacion (nombre, descripcion, capacidad)
VALUES ('ESTANDAR', 'Habitación estándar con comodidades básicas', 2);

INSERT INTO tipo_habitacion (nombre, descripcion, capacidad)
VALUES ('SUITE', 'Habitación de lujo con sala de estar separada', 4);

INSERT INTO tipo_habitacion (nombre, descripcion, capacidad)
VALUES ('SUPERIOR', 'Habitación superior con mejores vistas y comodidades', 3);


-- Tarifas
--Alta
INSERT INTO tarifa (id_tipo_habitacion, id_temporada, precio_noche)
VALUES (1, 1, 300.00); -- Estandar - Alta

INSERT INTO tarifa (id_tipo_habitacion, id_temporada, precio_noche)
VALUES (2, 1, 600.00); -- Suite - Alta

INSERT INTO tarifa (id_tipo_habitacion, id_temporada, precio_noche)
VALUES (3, 1, 450.00); -- Superior - Alta

--Media
INSERT INTO tarifa (id_tipo_habitacion, id_temporada, precio_noche)
VALUES (1, 2, 250.00); -- Estandar - Media

INSERT INTO tarifa (id_tipo_habitacion, id_temporada, precio_noche)
VALUES (2, 2, 550.00); -- Suite - Media

INSERT INTO tarifa (id_tipo_habitacion, id_temporada, precio_noche)
VALUES (3, 2, 350.00); -- Superior - Media

--Baja
INSERT INTO tarifa (id_tipo_habitacion, id_temporada, precio_noche)
VALUES (1, 3, 150.00); -- Estandar - Baja

INSERT INTO tarifa (id_tipo_habitacion, id_temporada, precio_noche)
VALUES (2, 3, 350.00); -- Suite - Baja

INSERT INTO tarifa (id_tipo_habitacion, id_temporada, precio_noche)
VALUES (3, 3, 250.00); -- Superior - Baja

--Alta 2026
INSERT INTO tarifa (id_tipo_habitacion, id_temporada, precio_noche)
VALUES (1, 4, 320.00); -- Estandar - Alta 2026

INSERT INTO tarifa (id_tipo_habitacion, id_temporada, precio_noche)
VALUES (2, 4, 620.00); -- Suite - Alta 2026

INSERT INTO tarifa (id_tipo_habitacion, id_temporada, precio_noche)
VALUES (3, 4, 470.00); -- Superior - Alta 2026

--Vistas
INSERT INTO vista (nombre, descripcion)
VALUES ('MAR', 'Vista al mar');

INSERT INTO vista (nombre, descripcion)
VALUES ('Jardin', 'Vista al jardin');

INSERT INTO vista (nombre, descripcion)
VALUES ('Interna', 'Sin vista exterior');

-- Habitaciones
-- Estandar - Vista Mar
INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (101, 'Estandar Mar 101', 'Habitación estándar con vista al mar', 1, 1);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (102, 'Estandar Mar 102', 'Habitación estándar con vista al mar', 1, 1);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (103, 'Estandar Mar 103', 'Habitación estándar con vista al mar', 1, 1);

-- Estandar - Vista Jardin
INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (201, 'Estandar Jardin 201', 'Habitación estándar con vista al jardin', 1, 2);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (202, 'Estandar Jardin 202', 'Habitación estándar con vista al jardin', 1, 2);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (203, 'Estandar Jardin 203', 'Habitación estándar con vista al jardin', 1, 2);

-- Estandar - Vista Interna
INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (301, 'Estandar Interna 301', 'Habitación estándar sin vista exterior', 1, 3);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (302, 'Estandar Interna 302', 'Habitación estándar sin vista exterior', 1, 3);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (303, 'Estandar Interna 303', 'Habitación estándar sin vista exterior', 1, 3);

-- Suite - Vista Mar
INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (104, 'Suite Mar 104', 'Suite de lujo con vista al mar', 2, 1);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (105, 'Suite Mar 105', 'Suite de lujo con vista al mar', 2, 1);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (106, 'Suite Mar 106', 'Suite de lujo con vista al mar', 2, 1);

-- Suite - Vista Jardin
INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (204, 'Suite Jardin 204', 'Suite de lujo con vista al jardin', 2, 2);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (205, 'Suite Jardin 205', 'Suite de lujo con vista al jardin', 2, 2);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (206, 'Suite Jardin 206', 'Suite de lujo con vista al jardin', 2, 2);

-- Suite - Vista Interna
INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (304, 'Suite Interna 304', 'Suite de lujo sin vista exterior', 2, 3);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (305, 'Suite Interna 305', 'Suite de lujo sin vista exterior', 2, 3);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (306, 'Suite Interna 306', 'Suite de lujo sin vista exterior', 2, 3);

-- Superior - Vista Mar
INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (107, 'Superior Mar 107', 'Habitación superior con vista al mar', 3, 1);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (108, 'Superior Mar 108', 'Habitación superior con vista al mar', 3, 1);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (109, 'Superior Mar 109', 'Habitación superior con vista al mar', 3, 1);

-- Superior - Vista Jardin
INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (207, 'Superior Jardin 207', 'Habitación superior con vista al jardin', 3, 2);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (208, 'Superior Jardin 208', 'Habitación superior con vista al jardin', 3, 2);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (209, 'Superior Jardin 209', 'Habitación superior con vista al jardin', 3, 2);

-- Superior - Vista Interna
INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (307, 'Superior Interna 307', 'Habitación superior sin vista exterior', 3, 3);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (308, 'Superior Interna 308', 'Habitación superior sin vista exterior', 3, 3);

INSERT INTO habitacion (numero_habitacion, nombre, descripcion, id_tipo_habitacion, id_vista)
VALUES (309, 'Superior Interna 309', 'Habitación superior sin vista exterior', 3, 3);


-- Cliente
INSERT INTO cliente (nombre, apellido, dni, email, telefono, fecha_nacimiento)
VALUES ('Facundo', 'Martinez Vidal', '43872046', 'fmartinezv@gmail.com', '1166660428', '2002-01-12');

INSERT INTO cliente (nombre, apellido, dni, email, telefono, fecha_nacimiento)
VALUES ('Iñaki', 'Moreno', '43668254', 'imorenog@gmail.com', '2396605576', '2001-10-5');

INSERT INTO cliente (nombre, apellido, dni, email, telefono, fecha_nacimiento)
VALUES ('Faure', 'Lucas', '43688022', 'lfaure@gmail.com', '2396605576', '2002-08-22');

-- Reserva
INSERT INTO reserva (id_cliente, fecha_checkin, fecha_checkout, total)
VALUES (1, '2025-12-15', '2025-12-20', 1600.00);

INSERT INTO detalle_reserva (id_reserva, id_habitacion, precio_noche, fecha_checkin, fecha_checkout, cant_noches)
VALUES (1, 1, 320.00, '2025-12-15', '2025-12-20', 5);

INSERT INTO reserva (id_cliente, fecha_checkin, fecha_checkout, total)
VALUES (2, '2025-12-18', '2025-12-22', 2480.00);

INSERT INTO detalle_reserva (id_reserva, id_habitacion, precio_noche, fecha_checkin, fecha_checkout, cant_noches)
VALUES (2, 10, 620.00, '2025-12-18', '2025-12-22', 4);

-- Alertas de ejemplo
INSERT INTO alerta (id_cliente, id_reserva, id_habitacion, tipo, descripcion, creado_por)
VALUES (1, 1, 1, 'REPETICION', 'Intento de duplicación bloqueado: mismo cliente, misma habitación, check-in cercano.', 'trg_validar_duplicacion_habitacion');

INSERT INTO alerta (id_cliente, id_reserva, id_habitacion, tipo, descripcion, creado_por)
VALUES (1, 1, 1, 'REPETICION', 'Intento de duplicación bloqueado: mismo cliente, misma habitación, check-in cercano.', 'trg_validar_duplicacion_habitacion');

INSERT INTO alerta (id_cliente, id_reserva, id_habitacion, tipo, descripcion, creado_por)
VALUES (2, 2, 10, 'REPETICION', 'Intento de duplicación bloqueado: mismo cliente, misma habitación, check-in cercano.', 'trg_validar_duplicacion_habitacion');

INSERT INTO alerta (id_cliente, id_habitacion, tipo, descripcion, creado_por)
VALUES (1, 5, 'ERROR', 'La habitación ya está reservada en las fechas solicitadas.', 'sp_reservar_habitacion');

INSERT INTO alerta (id_cliente, tipo, descripcion, creado_por)
VALUES (3, 'ERROR', 'El servicio adicional solicitado no existe o fue eliminado.', 'sp_reservar_habitacion');
