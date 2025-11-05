# Códigos de Error - Sistema de Reservas

## Convención SQL Server

- **Errores del Sistema**: 1 - 49999 (reservados por Microsoft)
- **Errores Personalizados**: 50000+ (para aplicaciones)

Todos los códigos personalizados comienzan en **50000** para evitar conflictos con errores internos de SQL Server.

---

## Categorías de Errores

### 📋 Validación de Parámetros (50000-50002)

| Código | Descripción | Severidad |
|--------|-------------|-----------|
| `50000` | `id_cliente` inválido (NULL o menor/igual a 0) | Alta |
| `50001` | `id_habitacion` inválido (NULL o menor/igual a 0) | Alta |
| `50002` | Fechas de reserva inválidas (NULL o fecha_inicio >= fecha_fin) | Alta |

**Origen**: Validación inicial de parámetros de entrada

---

### 🕐 Validación Temporal (50009)

| Código | Descripción | Severidad |
|--------|-------------|-----------|
| `50009` | Fecha de check-in es anterior a la fecha actual | Alta |

**Origen**: No se permiten reservas con check-in en el pasado

---

### 👤 Validación de Cliente (50003)

| Código | Descripción | Severidad |
|--------|-------------|-----------|
| `50003` | Cliente no existe, no está activo, o fue eliminado (soft delete) | Alta |

**Origen**: Verificación de existencia y estado del cliente

---

### 🏠 Validación de Habitación (50004)

| Código | Descripción | Severidad |
|--------|-------------|-----------|
| `50004` | Habitación no existe, no está disponible, o fue eliminada (soft delete) | Alta |

**Origen**: Verificación de existencia y disponibilidad de la habitación

---

### 🔁 Validación de Reservas Duplicadas (50005)

| Código | Descripción | Severidad |
|--------|-------------|-----------|
| `50005` | Cliente intenta reservar la misma habitación en fechas que se solapan con una reserva activa propia | Media |

**Tipo de Alerta**: `REPETICION`  
**Origen**: Prevención de reservas duplicadas del mismo cliente en la misma habitación

---

### ⚠️ Conflictos de Disponibilidad (50006)

| Código | Descripción | Severidad |
|--------|-------------|-----------|
| `50006` | Habitación ya está reservada por otro cliente en las fechas solicitadas | Media |

**Tipo de Alerta**: `ERROR`  
**Origen**: Conflicto de disponibilidad con reservas de otros clientes

---

### 💰 Validación de Tarifas y Temporadas (50007-50008)

| Código | Descripción | Severidad |
|--------|-------------|-----------|
| `50007` | No existe una temporada vigente para la fecha de inicio solicitada | Alta |
| `50008` | No existe una tarifa configurada para el tipo de habitación y temporada | Alta |

**Tipo de Alerta**: `ERROR`  
**Origen**: Problemas de configuración del sistema (tarifas o temporadas no definidas)

---

## Flujo de Validación

```
1. Validar parámetros de entrada (50000-50002)
   ↓
2. Validar fecha no sea pasada (50009)
   ↓
3. Validar cliente existe y activo (50003)
   ↓
4. Validar habitación existe y disponible (50004)
   ↓
5. Validar temporada existe (50007)
   ↓
6. Validar tarifa existe (50008)
   ↓
7. Validar reserva no duplicada (50005)
   ↓
8. Validar disponibilidad habitación (50006)
   ↓
9. Crear reserva ✅
```

---

## Manejo de Errores

Todos los errores utilizan el mecanismo `TRY-CATCH` con:

- **Transacciones**: Garantizan atomicidad (todo o nada)
- **Rollback automático**: Si ocurre un error, se revierten todos los cambios
- **Registro de alertas**: Los errores 50005-50008 generan registros en la tabla `alerta`
- **Propagación de errores**: El error se propaga con su mensaje, severidad y estado originales

### Estructura de Error

```sql
RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
```

Donde:
- `@ErrorMessage`: Mensaje descriptivo del error
- `@ErrorSeverity`: Nivel de severidad (generalmente 16)
- `@ErrorState`: Estado del error (generalmente 1)

---

## Tabla de Alertas

Los errores que generan alertas (`50005-50008`) se registran en:

```sql
dbo.alerta (
    id_cliente,
    id_reserva,
    id_habitacion,
    tipo,           -- 'REPETICION' o 'ERROR'
    descripcion     -- Mensaje detallado
)
```

### Tipos de Alerta

- **REPETICION** (50005): Cliente intenta duplicar su propia reserva
- **ERROR** (50006-50008): Conflictos de disponibilidad o configuración

---

## Notas Técnicas

1. **Soft Deletes**: Todas las validaciones verifican `fecha_eliminacion IS NULL`
2. **Estados Válidos**: 
   - Cliente: `ACTIVO`
   - Habitación: `DISPONIBLE`
   - Reserva: `PENDIENTE`, `CONFIRMADA`, `EN_CURSO`, `COMPLETADA`, `CANCELADA`
3. **Transaccionalidad**: Todas las operaciones son atómicas
4. **Auditoría**: Se registra `creado_por`, `fecha_creacion`, `fecha_modificacion`

