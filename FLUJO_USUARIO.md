# 🏨 Flujo Completo de Usuario - Resort Bahía Serena

## 📋 Índice

1. [Reserva Online](#paso-1-reserva-online)
2. [Pago de Seña](#paso-2-pago-de-seña)
3. [Check-in](#paso-3-check-in)
4. [Consumo de Servicios](#paso-4-consumo-de-servicios-adicionales)
5. [Check-out y Facturación](#paso-5-check-out-y-facturación)
6. [Pago Final](#paso-6-pago-final)
7. [Consultas de Verificación](#paso-7-consultas-de-verificación)
8. [Caso Walk-in (Sin Reserva)](#caso-especial-walk-in-sin-reserva)

---

## ⚠️ IMPORTANTE: Cuándo se Factura

### ❌ NO se emite factura en:

- La creación de la reserva
- El pago de seña/anticipo (solo recibo)
- El check-in

### ✅ SÍ se emite factura en:

- **Check-out**: Por consumos reales durante la estadía
- **Servicios puntuales**: Cliente ex## 📝 Notas Importantes

1. **Soft Deletes**: Todas las tablas tienen `fecha_eliminacion` para borrado lógico
2. **Trazabilidad**: Los precios se guardan en el momento de la reserva/compra
3. **Flexibilidad de Pagos**: Los pagos pueden existir antes que las facturas (seña)
4. **Flexibilidad de Facturas**: Las facturas pueden emitirse sin reserva (walk-ins)
5. **Referencias**: `detalle_factura` mantiene referencias a `detalle_reserva` y `reserva_servicio`
6. **Estados de Reserva**: PENDIENTE → CONFIRMADA → EN_CURSO → COMPLETADA
7. **Momento de Facturación**: La factura se emite al check-out, NO al reservar
8. **id_cliente en factura**: Permite facturar a clientes sin reserva (walk-ins)

---

## 🛠️ Ajuste Recomendado para Walk-ins

Para soportar completamente clientes walk-in, modificar la tabla `pago`:

```sql
-- Hacer id_reserva opcional
ALTER TABLE pago
ALTER COLUMN id_reserva INT NULL;

-- Agregar constraint: debe tener reserva O factura
ALTER TABLE pago
ADD CONSTRAINT CK_pago_reserva_o_factura
CHECK (id_reserva IS NOT NULL OR id_factura IS NOT NULL);
```

Esto permite:

- Pagos de seña sin factura: `id_reserva = 100, id_factura = NULL`
- Pagos walk-in sin reserva: `id_reserva = NULL, id_factura = 500`
- Pagos de saldo con ambos: `id_reserva = 100, id_factura = 1`

---

*Generado para Resort Bahía Serena - Sistema de Gestión Hotelera*eserva (walk-in)

---

## 📅 PASO 1: Reserva Online

**Escenario:** Juan Pérez reserva una habitación Suite para 3 noches (20-23 de diciembre) y contrata el servicio de Spa para 2 personas.

### 1.1. Registrar/Verificar Cliente

```sql
-- Insertar cliente nuevo
INSERT INTO cliente (nombre, apellido, dni, email, telefono, estado, fecha_nacimiento)
VALUES ('Juan', 'Pérez', '12345678', 'juan.perez@gmail.com', '1234567890', 'ACTIVO', '1990-05-15');

-- Supongamos que obtiene id_cliente = 1
```

### 1.2. Crear Reserva

```sql
INSERT INTO reserva (id_cliente, estado_reserva, fecha_checkin, fecha_checkout)
VALUES (1, 'PENDIENTE', '2025-12-20 14:00:00', '2025-12-23 10:00:00');

-- Supongamos que obtiene id_reserva = 100
```

### 1.3. Agregar Habitación a la Reserva

```sql
-- Buscar precio vigente de la tarifa (según temporada y tipo de habitación)
-- Para este ejemplo: Habitación 201, Suite, $15,000 por noche

INSERT INTO detalle_reserva (
    id_reserva,
    id_habitacion,
    precio_noche,
    fecha_checkin,
    fecha_checkout,
    cant_noches,
    subtotal
)
VALUES (100, 201, 15000.00, '2025-12-20 14:00:00', '2025-12-23 10:00:00', 3, 45000.00);
-- Subtotal hospedaje: 15,000 × 3 noches = 45,000
```

### 1.4. Agregar Servicio Adicional (Spa)

```sql
INSERT INTO reserva_servicio (
    id_reserva,
    id_servicio_adicional,
    cantidad,
    precio_unitario,
    fecha_servicio,
    subtotal
)
VALUES (100, 5, 2, 8000.00, '2025-12-21 16:00:00', 16000.00);
-- 2 personas al Spa: 8,000 × 2 = 16,000
-- id_reserva_servicio = 1
```

**📊 Estado Actual:**

- ✅ Reserva creada: `estado_reserva = 'PENDIENTE'`
- ✅ Hospedaje: **$45,000** (3 noches)
- ✅ Servicios: **$16,000** (Spa x2)
- 💰 **TOTAL A PAGAR: $61,000**

---

## 💳 PASO 2: Pago de Seña

**Escenario:** El cliente paga el 30% de seña para confirmar su reserva.

### 2.1. Registrar Pago de Seña

```sql
-- Seña del 30%: 61,000 × 0.30 = 18,300
INSERT INTO pago (
    id_reserva,
    id_factura,
    tipo_pago,
    metodo_pago,
    monto,
    estado,
    concepto
)
VALUES (
    100,
    NULL,  -- Aún no hay factura
    'SEÑA',
    'TARJETA_CREDITO',
    18300.00,
    'APROBADO',
    'Seña 30% reserva Habitación 201'
);
```

### 2.2. Confirmar Reserva

```sql
UPDATE reserva
SET estado_reserva = 'CONFIRMADA'
WHERE id_reserva = 100;
```

**📊 Estado Actual:**

- ✅ Seña pagada: **$18,300**
- 💰 Pendiente de pago: **$42,700**
- ✅ Reserva confirmada: `estado_reserva = 'CONFIRMADA'`

---

## 🚪 PASO 3: Check-in

**Fecha:** 20 de diciembre de 2025 a las 14:00 hs

### 3.1. Cambiar Estado de Reserva

```sql
UPDATE reserva
SET estado_reserva = 'EN_CURSO'
WHERE id_reserva = 100;
```

### 3.2. Actualizar Estado de Habitación (opcional)

```sql
-- Si tienes control de estado "OCUPADA" en habitacion
UPDATE habitacion
SET estado_operativo = 'OCUPADA'
WHERE id_habitacion = 201;
```

**📊 Estado Actual:**

- ✅ Cliente alojado
- ✅ Reserva: `estado_reserva = 'EN_CURSO'`
- 🏨 Habitación 201: Ocupada

---

## 🍽️ PASO 4: Consumo de Servicios Adicionales

**Escenario:** Durante su estadía, el cliente contrata servicios adicionales.

### 4.1. Cena Especial (21 de diciembre)

```sql
INSERT INTO reserva_servicio (
    id_reserva,
    id_servicio_adicional,
    cantidad,
    precio_unitario,
    fecha_servicio,
    subtotal
)
VALUES (100, 3, 2, 5000.00, '2025-12-21 20:00:00', 10000.00);
-- Cena para 2 personas: 5,000 × 2 = 10,000
-- id_reserva_servicio = 2
```

### 4.2. Masaje Extra (22 de diciembre)

```sql
INSERT INTO reserva_servicio (
    id_reserva,
    id_servicio_adicional,
    cantidad,
    precio_unitario,
    fecha_servicio,
    subtotal
)
VALUES (100, 5, 1, 8000.00, '2025-12-22 15:00:00', 8000.00);
-- Masaje adicional: 8,000 × 1 = 8,000
-- id_reserva_servicio = 3
```

**📊 Estado Actualizado:**

- 🏨 Hospedaje: **$45,000**
- 💆 Servicios totales: **$34,000** (16,000 + 10,000 + 8,000)
- 💰 **NUEVO TOTAL: $79,000**
- ✅ Ya pagado: $18,300
- ⚠️ **PENDIENTE: $60,700**

---

## 🏁 PASO 5: Check-out y Facturación

**Fecha:** 23 de diciembre de 2025 a las 10:00 hs

### 5.1. Calcular Totales de la Estadía

```sql
SELECT
    -- Hospedaje
    (SELECT SUM(subtotal)
     FROM detalle_reserva
     WHERE id_reserva = 100) AS total_hospedaje,

    -- Servicios
    (SELECT SUM(subtotal)
     FROM reserva_servicio
     WHERE id_reserva = 100) AS total_servicios,

    -- Total consumos
    (SELECT SUM(subtotal) FROM detalle_reserva WHERE id_reserva = 100) +
    (SELECT SUM(subtotal) FROM reserva_servicio WHERE id_reserva = 100) AS total_consumos,

    -- Ya pagado
    (SELECT COALESCE(SUM(monto), 0)
     FROM pago
     WHERE id_reserva = 100 AND estado = 'APROBADO') AS total_pagado,

    -- Saldo pendiente
    ((SELECT SUM(subtotal) FROM detalle_reserva WHERE id_reserva = 100) +
     (SELECT SUM(subtotal) FROM reserva_servicio WHERE id_reserva = 100)) -
    (SELECT COALESCE(SUM(monto), 0) FROM pago WHERE id_reserva = 100 AND estado = 'APROBADO') AS saldo_pendiente;
```

**📊 Resultado:**
| Concepto | Monto |
|----------|-------|
| Total Hospedaje | $45,000 |
| Total Servicios | $34,000 |
| **Total Consumos** | **$79,000** |
| Ya Pagado | $18,300 |
| **Saldo Pendiente** | **$60,700** |

### 5.2. Generar Factura Final

#### 5.2.1. Crear Factura

```sql
-- Cálculo de impuestos (ejemplo: IVA 8%)
-- Subtotal sin impuestos: 79,000 / 1.08 = 73,148.15
-- Impuestos: 79,000 - 73,148.15 = 5,851.85

INSERT INTO factura (
    id_cliente,
    id_reserva,
    numero_factura,
    tipo_comprobante,
    concepto,
    subtotal,
    impuestos,
    total,
    estado
)
VALUES (
    1,
    100,
    'F-2025-00001',
    'FACTURA',
    'Estadía Habitación 201 del 20 al 23 de diciembre',
    73148.15,
    5851.85,
    79000.00,
    'EMITIDA'
);
-- Supongamos id_factura = 1
```

#### 5.2.2. Detallar Hospedaje en Factura

```sql
INSERT INTO detalle_factura (
    id_factura,
    concepto,
    cantidad,
    precio_unitario,
    subtotal,
    id_detalle_reserva
)
VALUES (
    1,
    'Habitación Suite Vista Mar - 3 noches',
    3,
    15000.00,
    45000.00,
    1  -- Referencia al detalle_reserva
);
```

#### 5.2.3. Detallar Servicios en Factura

```sql
-- Spa inicial (2 personas)
INSERT INTO detalle_factura (
    id_factura, concepto, cantidad, precio_unitario, subtotal, id_reserva_servicio
)
VALUES (1, 'Spa - Masaje relajante (2 personas)', 2, 8000.00, 16000.00, 1);

-- Cena especial
INSERT INTO detalle_factura (
    id_factura, concepto, cantidad, precio_unitario, subtotal, id_reserva_servicio
)
VALUES (1, 'Cena Temática (2 personas)', 2, 5000.00, 10000.00, 2);

-- Masaje adicional
INSERT INTO detalle_factura (
    id_factura, concepto, cantidad, precio_unitario, subtotal, id_reserva_servicio
)
VALUES (1, 'Spa - Masaje relajante (1 persona)', 1, 8000.00, 8000.00, 3);
```

---

## 💰 PASO 6: Pago Final

### 6.1. Registrar Pago del Saldo

```sql
INSERT INTO pago (
    id_reserva,
    id_factura,
    tipo_pago,
    metodo_pago,
    monto,
    estado,
    concepto
)
VALUES (
    100,
    1,
    'SALDO',
    'TARJETA_CREDITO',
    60700.00,
    'APROBADO',
    'Pago saldo check-out'
);
```

### 6.2. Vincular Seña con Factura

```sql
-- Actualizar el pago de seña para vincularlo a la factura emitida
UPDATE pago
SET id_factura = 1
WHERE id_reserva = 100 AND tipo_pago = 'SEÑA';
```

### 6.3. Completar Reserva

```sql
-- Cambiar estado a COMPLETADA
UPDATE reserva
SET estado_reserva = 'COMPLETADA'
WHERE id_reserva = 100;

-- Liberar habitación
UPDATE habitacion
SET estado_operativo = 'DISPONIBLE'
WHERE id_habitacion = 201;
```

**📊 Estado Final:**

- ✅ Factura emitida: **F-2025-00001**
- ✅ Total facturado: **$79,000**
- ✅ Seña: **$18,300**
- ✅ Saldo: **$60,700**
- 💚 **PAGADO COMPLETO: $79,000**
- ✅ Reserva: `estado_reserva = 'COMPLETADA'`
- ✅ Habitación: `estado_operativo = 'DISPONIBLE'`

---

## 📊 PASO 7: Consultas de Verificación

### 7.1. Ver Factura Completa

```sql
SELECT
    f.numero_factura,
    f.fecha_emision,
    c.nombre + ' ' + c.apellido AS cliente,
    c.dni,
    c.email,
    df.concepto,
    df.cantidad,
    df.precio_unitario,
    df.subtotal,
    f.subtotal AS factura_subtotal,
    f.impuestos AS factura_impuestos,
    f.total AS factura_total
FROM factura f
JOIN cliente c ON f.id_cliente = c.id_cliente
JOIN detalle_factura df ON f.id_factura = df.id_factura
WHERE f.id_factura = 1
ORDER BY df.id_detalle_factura;
```

**Resultado esperado:**

| numero_factura | cliente    | concepto                              | cantidad | precio_unitario | subtotal  |
| -------------- | ---------- | ------------------------------------- | -------- | --------------- | --------- |
| F-2025-00001   | Juan Pérez | Habitación Suite Vista Mar - 3 noches | 3        | 15,000.00       | 45,000.00 |
| F-2025-00001   | Juan Pérez | Spa - Masaje relajante (2 personas)   | 2        | 8,000.00        | 16,000.00 |
| F-2025-00001   | Juan Pérez | Cena Temática (2 personas)            | 2        | 5,000.00        | 10,000.00 |
| F-2025-00001   | Juan Pérez | Spa - Masaje relajante (1 persona)    | 1        | 8,000.00        | 8,000.00  |

**Totales:**

- Subtotal sin IVA: $73,148.15
- IVA (8%): $5,851.85
- **TOTAL: $79,000.00**

### 7.2. Ver Historial de Pagos

```sql
SELECT
    p.tipo_pago,
    p.metodo_pago,
    p.monto,
    p.concepto,
    p.fecha_pago,
    p.estado,
    CASE
        WHEN p.id_factura IS NULL THEN 'Sin vincular'
        ELSE f.numero_factura
    END AS factura_asociada
FROM pago p
LEFT JOIN factura f ON p.id_factura = f.id_factura
WHERE p.id_reserva = 100 AND p.estado = 'APROBADO'
ORDER BY p.fecha_pago;
```

**Resultado esperado:**

| tipo_pago | metodo_pago     | monto     | concepto                        | fecha_pago          | factura_asociada |
| --------- | --------------- | --------- | ------------------------------- | ------------------- | ---------------- |
| SEÑA      | TARJETA_CREDITO | 18,300.00 | Seña 30% reserva Habitación 201 | 2025-11-15 10:30:00 | F-2025-00001     |
| SALDO     | TARJETA_CREDITO | 60,700.00 | Pago saldo check-out            | 2025-12-23 10:15:00 | F-2025-00001     |

**TOTAL PAGADO: $79,000.00** ✅

### 7.3. Verificar Saldo de Factura

```sql
SELECT
    f.numero_factura,
    f.total AS total_factura,
    COALESCE(SUM(p.monto), 0) AS total_pagado,
    f.total - COALESCE(SUM(p.monto), 0) AS saldo_pendiente,
    CASE
        WHEN f.total - COALESCE(SUM(p.monto), 0) = 0 THEN '✅ PAGADO'
        WHEN f.total - COALESCE(SUM(p.monto), 0) > 0 THEN '⚠️ PENDIENTE'
        ELSE '❌ ERROR'
    END AS estado_pago
FROM factura f
LEFT JOIN pago p ON f.id_factura = p.id_factura AND p.estado = 'APROBADO'
WHERE f.id_factura = 1
GROUP BY f.numero_factura, f.total;
```

**Resultado esperado:**

| numero_factura | total_factura | total_pagado | saldo_pendiente | estado_pago |
| -------------- | ------------- | ------------ | --------------- | ----------- |
| F-2025-00001   | 79,000.00     | 79,000.00    | 0.00            | ✅ PAGADO   |

### 7.4. Resumen de la Reserva

```sql
SELECT
    r.id_reserva,
    c.nombre + ' ' + c.apellido AS cliente,
    r.estado_reserva,
    r.fecha_checkin,
    r.fecha_checkout,
    -- Hospedaje
    (SELECT SUM(dr.subtotal) FROM detalle_reserva dr WHERE dr.id_reserva = r.id_reserva) AS total_hospedaje,
    -- Servicios
    (SELECT SUM(rs.subtotal) FROM reserva_servicio rs WHERE rs.id_reserva = r.id_reserva) AS total_servicios,
    -- Total
    (SELECT SUM(dr.subtotal) FROM detalle_reserva dr WHERE dr.id_reserva = r.id_reserva) +
    (SELECT SUM(rs.subtotal) FROM reserva_servicio rs WHERE rs.id_reserva = r.id_reserva) AS total_reserva,
    -- Factura
    (SELECT numero_factura FROM factura WHERE id_reserva = r.id_reserva) AS numero_factura,
    -- Pagos
    (SELECT COALESCE(SUM(monto), 0) FROM pago WHERE id_reserva = r.id_reserva AND estado = 'APROBADO') AS total_pagado
FROM reserva r
JOIN cliente c ON r.id_cliente = c.id_cliente
WHERE r.id_reserva = 100;
```

**Resultado esperado:**

| id_reserva | cliente    | estado_reserva | fecha_checkin    | fecha_checkout   | total_hospedaje | total_servicios | total_reserva | numero_factura | total_pagado |
| ---------- | ---------- | -------------- | ---------------- | ---------------- | --------------- | --------------- | ------------- | -------------- | ------------ |
| 100        | Juan Pérez | COMPLETADA     | 2025-12-20 14:00 | 2025-12-23 10:00 | 45,000.00       | 34,000.00       | 79,000.00     | F-2025-00001   | 79,000.00    |

---

## 📈 Diagrama de Flujo Simplificado

```
┌─────────────────┐
│  1. RESERVA     │  → estado_reserva: 'PENDIENTE'
│  Online         │     Total: $79,000
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  2. PAGO SEÑA   │  → estado_reserva: 'CONFIRMADA'
│  30% = $18,300  │     Pendiente: $60,700
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  3. CHECK-IN    │  → estado_reserva: 'EN_CURSO'
│  20/12 14:00    │     habitacion: 'OCUPADA'
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  4. SERVICIOS   │  → Cena: $10,000
│  Adicionales    │     Masaje: $8,000
└────────┬────────┘     NUEVO TOTAL: $79,000
         │
         ▼
┌─────────────────┐
│  5. CHECK-OUT   │  → Genera FACTURA
│  23/12 10:00    │     F-2025-00001
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  6. PAGO SALDO  │  → Paga $60,700
│  $60,700        │     Total pagado: $79,000 ✅
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  7. FINALIZA    │  → estado_reserva: 'COMPLETADA'
│  Reserva        │     habitacion: 'DISPONIBLE'
└─────────────────┘
```

---

## 🎯 Resumen Final

| Concepto                  | Valor                  |
| ------------------------- | ---------------------- |
| **Hospedaje (3 noches)**  | $45,000                |
| **Servicios adicionales** | $34,000                |
| **Total**                 | **$79,000**            |
| Seña (30%)                | $18,300 ✅             |
| Saldo final               | $60,700 ✅             |
| **Estado**                | **PAGADO COMPLETO** ✅ |

---

## � CASO ESPECIAL: Walk-in (Sin Reserva)

**Escenario:** Cliente externo usa servicios del hotel sin estar alojado.

### Ejemplo 1: Cena en el Restaurant

```sql
-- 1. Verificar/crear cliente
INSERT INTO cliente (nombre, apellido, dni, email, telefono, estado, fecha_nacimiento)
VALUES ('María', 'González', '87654321', 'maria.gonzalez@gmail.com', '0987654321', 'ACTIVO', '1985-03-10');
-- id_cliente = 50

-- 2. NO hay reserva, consumo directo
-- El cliente NO necesita reserva para consumir

-- 3. Registrar servicio consumido (opcional, para trazabilidad)
-- Si querés trackear: crear reserva "virtual" solo para servicios
-- O simplemente registrar en la factura directamente

-- 4. Emitir factura INMEDIATA (al momento del consumo)
INSERT INTO factura (
    id_cliente,     -- ✅ Tiene cliente
    id_reserva,     -- ❌ NULL - No tiene reserva
    numero_factura,
    tipo_comprobante,
    concepto,
    subtotal,
    impuestos,
    total,
    estado
)
VALUES (
    50,             -- Cliente walk-in
    NULL,           -- Sin reserva
    'F-2025-00500',
    'FACTURA',
    'Consumo restaurant',
    9259.26,        -- Sin IVA
    740.74,         -- IVA 8%
    10000.00,
    'EMITIDA'
);
-- id_factura = 500

-- 5. Detallar items de la factura
INSERT INTO detalle_factura (
    id_factura,
    concepto,
    cantidad,
    precio_unitario,
    subtotal,
    id_detalle_reserva,      -- NULL
    id_reserva_servicio      -- NULL o referencia si registraste
)
VALUES
(500, 'Cena para 2 personas', 2, 5000.00, 10000.00, NULL, NULL);

-- 6. Registrar pago INMEDIATO
-- PROBLEMA: La tabla pago requiere id_reserva
-- SOLUCIÓN: Crear reserva "virtual" o modificar tabla pago
```

### 🔧 Ajuste Necesario para Walk-ins

**Actualmente tu tabla `pago` requiere `id_reserva`:**

```sql
CREATE TABLE pago(
    id_reserva INT,  -- ⚠️ NOT NULL implícito por FK
    ...
);
```

**Opciones para soportar walk-ins:**

#### Opción A: Hacer `id_reserva` opcional (Recomendado ✅)

```sql
CREATE TABLE pago(
    id_pago INT PRIMARY KEY IDENTITY (1,1),
    id_reserva INT NULL,        -- ✅ Ahora puede ser NULL
    id_factura INT NULL,
    ...
    FOREIGN KEY (id_reserva) REFERENCES reserva(id_reserva),
    FOREIGN KEY (id_factura) REFERENCES factura(id_factura)
);

-- Registrar pago walk-in
INSERT INTO pago (
    id_reserva,     -- NULL (no hay reserva)
    id_factura,     -- Factura walk-in
    tipo_pago,      -- 'CONSUMO'
    metodo_pago,
    monto,
    estado,
    concepto
)
VALUES (NULL, 500, 'CONSUMO', 'TARJETA_CREDITO', 10000.00, 'APROBADO', 'Pago cena restaurant');
```

#### Opción B: Vincular pago solo a factura

```sql
-- Cambiar lógica: el pago puede vincular a reserva O a factura (al menos uno)
ALTER TABLE pago ADD CHECK (id_reserva IS NOT NULL OR id_factura IS NOT NULL);
```

### Flujo Walk-in Completo

```
┌─────────────────────┐
│  Cliente llega      │
│  sin reserva        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Consume servicio   │  (Restaurant, Spa, etc.)
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Emite FACTURA      │  id_cliente: ✅
│  inmediatamente     │  id_reserva: NULL
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Paga y se va       │
└─────────────────────┘
```

---

## 📊 Comparación: Huésped vs Walk-in

| Aspecto                   | Huésped Alojado        | Cliente Walk-in         |
| ------------------------- | ---------------------- | ----------------------- |
| **Tiene reserva**         | ✅ Sí                  | ❌ No                   |
| **Cuándo factura**        | Al check-out           | Inmediatamente          |
| **factura.id_reserva**    | ✅ Tiene valor         | ❌ NULL                 |
| **factura.id_cliente**    | ✅ Requerido           | ✅ Requerido            |
| **Permite seña/anticipo** | ✅ Sí                  | ❌ No (pago inmediato)  |
| **Puede pagar después**   | ✅ Sí (cuenta abierta) | ❌ No (pago al momento) |

---

## 🔑 Por qué `factura` tiene `id_cliente` e `id_reserva`

```sql
CREATE TABLE factura(
    id_cliente INT NOT NULL,    -- ✅ Siempre hay cliente
    id_reserva INT NULL,        -- ✅ Puede no haber reserva
    ...
);
```

### Beneficios del diseño:

1. **Flexibilidad**: Soporta huéspedes Y walk-ins
2. **Performance**: Acceso directo a datos del cliente sin JOIN
3. **Integridad**: Garantiza que toda factura tenga un cliente responsable
4. **Trazabilidad**: Relaciona factura con reserva cuando existe

### Ejemplos de queries:

```sql
-- Todas las facturas de un cliente (con o sin reserva)
SELECT * FROM factura WHERE id_cliente = 1;

-- Facturas de walk-ins (sin reserva)
SELECT * FROM factura WHERE id_reserva IS NULL;

-- Facturas de una reserva específica
SELECT * FROM factura WHERE id_reserva = 100;

-- Historial completo de un cliente
SELECT
    f.numero_factura,
    f.fecha_emision,
    f.total,
    CASE
        WHEN f.id_reserva IS NOT NULL THEN 'Estadía'
        ELSE 'Walk-in'
    END AS tipo_consumo
FROM factura f
WHERE f.id_cliente = 1;
```

---

## �📝 Notas Importantes

1. **Soft Deletes**: Todas las tablas tienen `fecha_eliminacion` para borrado lógico
2. **Trazabilidad**: Los precios se guardan en el momento de la reserva/compra
3. **Flexibilidad**: Los pagos pueden existir antes que las facturas (seña)
4. **Referencias**: `detalle_factura` mantiene referencias a `detalle_reserva` y `reserva_servicio`
5. **Estados**: La reserva pasa por: PENDIENTE → CONFIRMADA → EN_CURSO → COMPLETADA

---

_Generado para Resort Bahía Serena - Sistema de Gestión Hotelera_
