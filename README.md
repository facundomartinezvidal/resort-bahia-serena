# resort-bahia-serena

“Bahía Serena” es un hotel resort frente al mar que combina alojamiento y
experiencias. Dispone de tres tipos de habitación —Estandar, Superior y Suite—
diseñados para familias, parejas y viajeros corporativos. Cada habitación tiene un
código único, piso, vista (Mar, Jardín, Interna), capacidad determinada por el tipo,
y un estado operativo que puede ser Disponible, Fuera de Servicio (en
mantenimiento) o Inactiva. La correcta gestión de estados es crítica: ninguna
habitación Inactiva o Fuera de Servicio puede venderse.
La comercialización se organiza por temporadas (Alta, Media, Baja), con tarifas
diferenciadas por tipo de habitación y rango de fechas (p. ej., Alta del 15/12 al
28/02). La tarifa vigente al check-in define el precio por noche. Finanzas exige
trazabilidad: si más adelante la tarifa cambia, la reserva debe conservar el precio
aplicado en el momento de la operación. En temporadas pico, Marketing lanza
promos (descuentos o upgrades), pero para este TPO bastará con tarifas base por
rango.
Los clientes se registran con datos personales y un estado (Activo/Inactivo).
Realizan reservas indicando check-in y check-out. Una misma reserva puede
incluir una o varias habitaciones (familias o grupos) y, además, consumos de
servicios adicionales durante la estadía: Spa, Traslado Aeropuerto, Cena Temática,
Excursión Atardecer, Alquiler de Bicicletas, etc. Cada servicio tiene costo, precio y
cupo Diario (máximos por día); cuando un servicio alcanza su cupo, no debería
venderse más ese día para evitar sobrecarga operativa.
Operativamente, se detectaron errores frecuentes en la carga: el mismo cliente
intenta reservar la misma habitación para el mismo check-in más de una vez
(doble clic, reintento por conexión, etc.). Para cuidar la integridad operativa,
dirección establece una regla: ante ese patrón, la segunda carga debe bloquearse
y registrarse en un log de ALERTAS como Repetición. Asimismo, si no existe tarifa

vigente para la fecha de check-in del tipo de habitación seleccionado, la
operación debe rechazarse y documentarse como Error.
El área de Mantenimiento marca habitaciones como FueraServicio cuando hay
arreglos o inspecciones. Operaciones necesita una tarea de higienización que
inactiva automáticamente esas habitaciones (pasarlas a Inactiva hasta su
reactivación), dejando constancia en ALERTAS (tipo Mantenimiento). Este
procedimiento evita que Recepción ofrezca habitaciones en reparación y mejora
la calidad del inventario visible.
