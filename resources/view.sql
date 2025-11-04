-- 2
CREATE OR ALTER VIEW dbo.vw_habitaciones_repetidas AS
SELECT
    a.id_cliente,
    c.nombre + ' ' + c.apellido AS nombre_cliente,
    c.dni,
    a.id_habitacion,
    h.nombre AS nombre_habitacion,
    COUNT(*) AS cantidad_intentos,
    MIN(a.fecha_creacion) AS primer_intento,
    MAX(a.fecha_creacion) AS ultimo_intento,
    a.id_reserva,
    a.tipo
FROM alerta a
INNER JOIN cliente c ON a.id_cliente = c.id_cliente
INNER JOIN habitacion h ON a.id_habitacion = h.id_habitacion
WHERE a.tipo = 'REPETICION'
GROUP BY
    a.id_cliente,
    a.id_reserva,
    a.tipo,
    c.nombre,
    c.apellido,
    c.dni,
    a.id_habitacion,
    h.nombre
HAVING COUNT(*) >= 1;


