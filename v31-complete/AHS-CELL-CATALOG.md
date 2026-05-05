# AHS Cell Catalog
## AHS.SaaS Ecosystem | Blueprint V3.1.2
## Este documento SÍ cambia cuando se añaden, renombran o retiran Cells.
## La Constitución (Blueprint) NO cambia por eventos de este catálogo.

---

## FIXED COMPONENTS (no son Cells — son infraestructura del ecosistema)

| Component | Namespace | Product Name | Rol |
|---|---|---|---|
| Shell | AHS.Web.Hive | AHS Hive | Organismo orquestador — coordina todas las Cells |
| Design System | AHS.Web.Common | Sovereign Elite | RCL compartido — GlassCard, AhsGrid, ReasonForChangeModal |
| Foundation | AHS.Common | — | GxP Ledger, TenantContext, SIMD engines, ICellEvent |
| Aggregator | AHS.ControlTower.BFF | — | BFF real-time + analítico (⏳ pendiente) |

**AHS Hive — Metáfora biológica canónica:**
```
Hive            = el organismo completo
Cells           = órganos autónomos
GxP Ledger      = memoria inmutable
AOT compilation = existe sin depender del JIT
Sovereign Elite = el exoesqueleto (identidad visual)
```

---

## CELL REGISTRY

### 🟢 CELL: Xinfer
**Status:** Active — compilando, 7/7 tests verdes

| Campo | Valor |
|---|---|
| Namespace | `AHS.Cell.Xinfer` |
| Product Name | AHS Xinfer |
| Tagline | "Predict. Explain. Prevent." |
| Naming | X = Excursion (término FDA/GxP para desviación de temperatura) |
| Pronunciación | "ex-in-fer" |
| Subdomain | Core Domain |
| Buyer | VP Quality / QA Director (farmacéutica, alimentaria, química) |
| Predecessor | AHS.Cell.ColdChain (renombrado 2026-03) |

**Misión:**
Inferencia de riesgo de excursión antes de que ocurra.
Predice, explica (XAI DNA 14 factores) y recomienda acciones.

**Las 7 responsabilidades (orden obligatorio — invariante de dominio):**
```
1. Interpretar datos del embarque  → ShipmentIdentity + CarrierProfile
2. Data Readiness (9 validaciones) → Acceptable | Risky | NotAcceptable
3. Detección de divergencia        → ruta, carrier, packaging, estación
4. Selección de históricos         → registros compatibles, sin outliers
5. Decisión de reentrenamiento     → 6 criterios
6. Reentrenamiento (si aprobado)   → ModelVersion(n+1)
7. Predicción                      → RiskScore + XAI DNA 14 factores
8. Recomendaciones                 → reglas auditables GxP
```

**Reglas de dominio críticas:**
```
- Carrier = modificador de riesgo, NO parte de la identidad del embarque
- XAI DNA = exactamente 14 factores (invariante)
- Passive insulation = +15% penalidad base (REQ-001)
- Pessimistic TTF = PhysicalTtf × (1 - riskScore/100 × 0.60)
- Data Readiness BLOQUEA predicción si: Pharma+Passive+>48h o dataset<5
```

**Adaptadores de entrada (4):**
```
Local    → CSV/Excel desde wwwroot/data/ (modo demo actual)
Azure    → Azure Blob Storage / Event Hub
OCI      → Oracle Cloud Infrastructure
Firebase → Firebase Realtime Database
```

**Eventos publicados (Service Bus topic: ahs.xinfer.events):**
```
READINESS_OK      → ReadinessOkEvent
READINESS_FAIL    → ReadinessFailEvent
RETRAIN_REQUIRED  → RetrainRequiredEvent
PREDICT_OK        → PredictOkEvent
```

**Estado de implementación:**
```
✅ AHS.Cell.Xinfer.Domain           — compilando
✅ AHS.Cell.Xinfer.Application      — compilando
✅ AHS.Cell.Xinfer.Infrastructure   — compilando
✅ AHS.Cell.Xinfer.Contracts        — compilando
✅ AHS.Cell.Xinfer.API              — 0 errores, 0 warnings
✅ AHS.Cell.Xinfer.Tests            — 7/7 Unit + Architecture verdes
⚠️  Integration tests              — pendientes (requieren Docker)
⚠️  Xinfer V2.0 (7 responsabilidades) — PM listo, pendiente ejecución por AG
```

**Historia:**
```
2026-02  ColdChain Cell creada (arquitectura V2.0, Vertical Slice)
2026-03  Migrada a Clean Architecture + DDD + CQRS (Blueprint V3.1)
2026-03  Renombrada ColdChain → Xinfer (ADR de naming V3.1.2)
2026-03  Xinfer V2.0 diseñada — 7 responsabilidades autónomas
```

---

### 🟡 CELL: AssetManager
**Status:** Planned — Cell Canvas definido, no implementado

| Campo | Valor |
|---|---|
| Namespace | `AHS.Cell.AssetManager` (futuro) |
| Product Name | AHS AssetTrack |
| Subdomain | Supporting Domain |
| Buyer | Maintenance Manager / Operations Director |

**Misión:** Gestión GxP del ciclo de vida de activos industriales.

**Conecta con Xinfer:**
Reacciona a `PredictOkEvent` de Xinfer → marca el activo como "AtRisk"
cuando se detecta riesgo de excursión en un embarque que usa ese activo.

**P0 MVP:**
```
- Registro de activos con número de serie y categoría
- Programación y registro de mantenimientos
- Tracking de calibración con alertas de vencimiento
- Retiro de activos con audit trail GxP completo
- Exportación de historial para inspección regulatoria
```

---

### 🟡 CELL: FinTracker
**Status:** Planned — Cell Canvas definido, no implementado

| Campo | Valor |
|---|---|
| Namespace | `AHS.Cell.FinTracker` (futuro) |
| Product Name | AHS FinLens |
| Subdomain | Supporting Domain |
| Buyer | CFO / Finance Director (logística) |

**Misión:** Tracking multi-moneda de costos logísticos.

**Conecta con Xinfer:**
Reacciona a `PredictOkEvent` → trigger de registro de costos de seguro
cuando Xinfer detecta riesgo crítico en un embarque.

---

### ⬜ CELL: ShopifyBridge
**Status:** Conceptual — no diseñado

| Campo | Valor |
|---|---|
| Namespace | `AHS.Cell.ShopifyBridge` (futuro) |
| Subdomain | Supporting Domain |
| Pattern | Conformist → adopta el modelo de Shopify sin ACL |

---

## CELL LIFECYCLE STATES

```
⬜ Conceptual    → idea identificada, sin Cell Canvas
🟡 Planned       → Cell Canvas completo, Prompt Maestro pendiente
🔵 In Progress   → AG generando código
🟢 Active        → compilando, tests verdes, en uso
🔴 Deprecated    → reemplazada o retirada
```

---

## RENAME HISTORY

| Fecha | De | A | Motivo |
|---|---|---|---|
| 2026-03 | AHS.Cell.ColdChain | AHS.Cell.Xinfer | Nombre describe sector (frío), no capacidad (inferencia) |
| 2026-03 | AHS.Web.UI | AHS.Web.Hive | Nombre genérico → metáfora biológica del ecosistema |

---
*AHS Cell Catalog | Actualizar cuando se añada, renombre o retire una Cell*
*La Constitución (Blueprint Supplement) NO debe modificarse por cambios en este catálogo*
