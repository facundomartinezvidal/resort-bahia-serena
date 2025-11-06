# resort-bahia-serena

## Trabajo Práctico - Ingeniería de Datos I

**Universidad:** Universidad Argentina de la Empresa  
**Materia:** Ingeniería de Datos I  
**Profesor:** Montero, Juan Carlos  
**Fecha de entrega:** 5/11/2025

### Integrantes

- Iñaki Moreno - 1156320
- Lucas Faure - 1138280
- Facundo Martínez Vidal - 1156810
- Felipe Leandro Veiga - 1184792
- Martín Amadeo Noblia - 1177016

---

## Descripción del Proyecto

"Bahía Serena" es un hotel resort frente al mar que combina alojamiento y
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

En cuanto a reportes y cálculos sencillos, la gerencia solicita recursos reutilizables:

1. Una función que calcule el margen de un servicio (precio − costo) para
   análisis de rentabilidad;
2. Una vista que liste habitaciones repetidas por cliente y check-in, para
   auditoría de errores;
3. Un procedimiento para registrar reservas que: valide cliente activo,
   compruebe habitaciones disponibles, determine la tarifa aplicable por tipo
   y fecha, calcule subtotal por habitación y total de la reserva;
4. Un trigger que impida la duplicación de la misma habitación para el
   mismo cliente en el mismo check-in;
5. Un cursor que inactiva habitaciones Fuera de Servicio y deja registro en
   ALERTAS.

---

## Estructura del Proyecto

### Archivos Principales

- **`database.sql`** - Script de creación de la base de datos completa con todas las tablas, constraints y validaciones del sistema.
- **`seed.sql`** - Datos de prueba para poblar la base de datos con temporadas, tipos de habitación, habitaciones, tarifas, servicios adicionales y clientes de ejemplo.

### Carpeta `/resources`

Contiene los recursos SQL implementados según los requerimientos del negocio:

- **`function.sql`** - Función `fn_calcular_margen_servicio` que calcula el margen de rentabilidad (precio - costo) de un servicio adicional.

- **`view.sql`** - Vista `vw_habitaciones_repetidas` que lista intentos de reserva duplicados por cliente y habitación para auditoría de errores.

- **`procedure.sql`** - Procedimiento almacenado `sp_reservar_habitacion` que gestiona el proceso completo de reservas validando cliente activo, disponibilidad de habitaciones, tarifas vigentes y cálculo de totales.

- **`trigger.sql`** - Trigger `trg_validar_duplicacion_habitacion` que previene la duplicación de reservas (mismo cliente, misma habitación, mismo check-in) y registra alertas de tipo REPETICION.

- **`cursor.sql`** - Procedimiento `sp_inactivar_habitaciones_fuera_servicio` con cursor que procesa habitaciones en estado FUERA_SERVICIO, las marca como INACTIVA y registra alertas de tipo MANTENIMIENTO.

- **`alerta.sql`** - Procedimiento auxiliar `sp_registrar_alerta` para centralizar el registro de alertas operativas del sistema.
