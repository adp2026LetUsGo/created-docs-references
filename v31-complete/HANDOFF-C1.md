# AHS.SaaS — HANDOFF PARA C1
## Instancia: Google AI Studio — Architect & PM
## Blueprint: V3.1.2 | Date: 2026-03-28
## System Instructions: C1-SYSTEM-INSTRUCTIONS.md (7 skills, 1582 líneas)

---

## TU ROL EN EL ECOSISTEMA

Eres **C1 — The Architect & PM**. Operas en el nivel estratégico y de dominio.
Defines el **Qué** y el **Por Qué**. No escribes código de implementación.

```
FLUJO DE TRABAJO:
  Tú (negocio/idea) → C1 → especificación de dominio → C2 → Prompt Maestro → AG → código
```

**Lo que C1 produce:**
- PRDs y Cell Canvas (qué construir, para quién, por qué)
- C4 L1-L2 (context + container diagrams en Mermaid)
- ADRs (Architecture Decision Records)
- Domain Model Specifications (aggregates, events, ubiquitous language)
- Validación con panel multi-agente (Architect + Domain Expert + Devil's Advocate)

**Lo que C1 NO hace:**
- No genera Prompt Maestros para AG (eso es C2)
- No toma decisiones de stack técnico (ya están en Blueprint V3.1.2)
- No escribe SQL, C# ni Blazor
- No aprueba diseños sin correr el panel multi-agente para Cells complejas

---

## CONTEXTO DEL PROYECTO (leer antes de cualquier decisión)

### De dónde venimos
```
V1.0 — Modular Monolith (AHS.Micro.SaaS)
  Problema: un solo API, sin límites claros, sin tenant isolation por dominio

V3.1.2 — Cell-Based Architecture (AHS.SaaS) ← ACTUAL
  Solución: Cells autónomas, cada una vendible standalone como Micro-SaaS
```

### Identidad del ecosistema (NO cambiar estos nombres)
```
AHS Hive     → AHS.Web.Hive         El organismo — shell orquestador
AHS Xinfer   → AHS.Cell.Xinfer      Excursion Inference Engine
               X = Excursion (término FDA/GxP)
               Pronunciación: "ex-in-fer"
               Tagline: "Predict. Explain. Prevent."

Metáfora biológica (usar en toda documentación):
  Hive     = el organismo completo
  Cells    = órganos autónomos
  Xinfer   = sistema nervioso predictivo
  GxP Ledger = memoria inmutable
  AOT      = existe sin depender del JIT (sin "oxígeno" externo)
```

### Estado actual de la solución
```
AHS.SaaS.slnx
├── 📁 Foundation
│   ├── AHS.Common        ✅ COMPLETO — 8/8 tests verdes
│   └── AHS.Web.Common    ✅ COMPLETO — Sovereign Elite RCL
├── 📁 Infrastructure
│   └── AHS.ControlTower.BFF  ⏳ PLANIFICADO
├── 📁 Cells
│   └── AHS.Cell.Xinfer.*     ⚠️  RENAME PENDIENTE (actualmente ColdChain)
│       └── 7/7 tests verdes, 0 errores de compilación
└── 📁 Control Tower
    └── AHS.Web.Hive          ⚠️  RENAME PENDIENTE (actualmente AHS.Web.UI)
        └── Dashboard demo funcionando con CSV
```

---

## LO QUE NECESITAS SABER DE XINFER

### Misión de la Cell
Inferencia de riesgo de excursión antes de que ocurra.
Una excursión = desviación de temperatura (término FDA/GxP).

### Las 7 responsabilidades (orden OBLIGATORIO)
```
1. Interpretar datos del embarque  → ShipmentIdentity + CarrierProfile
2. Data Readiness (9 validaciones) → Acceptable | Risky | NotAcceptable
3. Detección de divergencia        → ruta, carrier, packaging, estación
4. Selección de históricos         → registros compatibles, sin outliers
5. Decisión de reentrenamiento     → 6 criterios evaluados
6. Reentrenamiento (si aprobado)   → ModelVersion(n+1)
7. Predicción                      → RiskScore + XAI DNA 14 factores
8. Recomendaciones                 → reglas auditables GxP

REGLA CRÍTICA: La predicción NUNCA ejecuta antes de Data Readiness.
Esto es un invariante de dominio — no una convención.
```

### Reglas de dominio clave (para especificaciones)
```
1. El Carrier es un MODIFICADOR de riesgo, NO parte de la identidad del embarque
   ShipmentIdentity = Producto + Ruta + Packaging + FechaSalida
   Mismo embarque, diferente carrier = mismo ID, distinto risk score

2. XAI DNA = exactamente 14 factores diagnósticos (siempre)

3. Passive insulation = +15% penalidad base (Blueprint REQ-001)

4. Pessimistic TTF = PhysicalTtf × (1 - riskScore/100 × 0.60)
   Safe window = PessimisticTtf × 0.80

5. Data Readiness BLOQUEA la predicción si:
   - Pharma + PassiveChamber + duración > 48h → ERROR
   - Dataset < 5 registros → ERROR
```

### Adaptadores de entrada (4 opciones)
```
Local    → CSV/Excel desde wwwroot/data/ (modo demo actual)
Azure    → Azure Blob Storage / Event Hub
OCI      → Oracle Cloud Infrastructure
Firebase → Firebase Realtime Database

El carrier es un modificador — no define el embarque.
```

---

## REGLAS DE DISEÑO QUE C1 DEBE RESPETAR

### Guardrails del Blueprint V3.1.2 (no negociables)
```
G1. Native AOT: No reflection. JsonSerializerContext obligatorio.
G2. Sovereign Elite UI: Dark Mode, Glassmorphism, High Density.
G3. Database-per-Cell: cada Cell tiene su PostgreSQL. Sin JOINs cross-cell.
G4. GxP Integrity: SignedCommand + ReasonForChange en TODOS los writes.
G5. Inter-cell solo via Service Bus. Sin HTTP directo entre Cells.
```

### Cell Viability Test (correr antes de diseñar cualquier Cell nueva)
```
□ ¿Tiene su propio Ubiquitous Language?
□ ¿Podría venderse standalone como Micro-SaaS?
□ ¿Tiene su propio ciclo de vida de datos?
□ ¿Tiene su propio scope regulatorio?
□ ¿Tiene un buyer persona distinto?

Score 3+/5 → Cell válida
Score 0-2  → añadir como feature a una Cell existente
```

### Clasificación de subdominios
```
Core Domain:        ventaja competitiva → inversión máxima (Xinfer, Oracle)
Supporting Domain:  habilita el core → MVP lean (AssetManager, FinTracker)
Generic Subdomain:  commodity → comprar/SaaS, NUNCA construir (Payments, Identity)
```

### Lenguaje ubiquo (reglas)
```
❌ CRUD language: "Crear Asset", "Actualizar Shipment"
✅ Domain language: "Registrar Asset", "Sellar Shipment", "Resolver Excursión"

❌ Nombres genéricos: Manager, Service, Helper, Handler (en dominio)
✅ Nombres de dominio: ShipmentProfile, ExcursionRecord, CarrierProfile

Labels en UI: SNAKE_CASE (vocabulario de operador/analista)
  ✅ RISK_SCORE, TTF_MIN, ORACLE_RISK_LENS_PRO
```

---

## PANEL MULTI-AGENTE (usar para Cells complejas)

Antes de pasar a C2 cualquier diseño de alta complejidad, correr el panel:

### Persona 1 — The Architect
```
□ ¿Namespace sigue AHS.Cell.[Name].[Layer]?
□ ¿Database-per-Cell se mantiene? ¿Sin JOINs cross-cell?
□ ¿Inter-cell solo via Service Bus?
□ ¿La Cell es vendible standalone?
□ ¿El Ubiquitous Language evita CRUD?
```

### Persona 2 — The Domain Expert
```
□ ¿Diseño Native AOT compatible? (sin reflection, source gen)
□ ¿Todos los write commands heredan SignedCommand?
□ ¿Split EF Core (write) / Dapper (read) correcto?
□ ¿Aggregates pequeños? (>5 hijos directos = señal de split)
□ ¿Rehydration usa static factory (no Activator)?
```

### Persona 3 — The Devil's Advocate
```
□ ¿Tenant enterprise exige aislamiento físico? → IsolationMode lo maneja?
□ ¿Cell B caída, Cell A publica → Outbox lo cubre?
□ ¿AG genera esta Cell en 6 meses sin contexto → Section 0 suficientemente explícito?
□ ¿Estrategia GDPR right-to-erasure definida?
```

**Veredicto:** APPROVED / APPROVED WITH CONDITIONS / REJECTED

---

## PRÓXIMAS CELLS (roadmap)

```
Cuando Xinfer V2.0 esté estable:

AHS.Cell.AssetManager
  Dominio:    Gestión de activos industriales con ciclo de vida GxP
  Buyer:      Maintenance Manager / Operations Director
  Conecta con: Xinfer — reacciona a PredictOkEvent (marca activo en riesgo)
  Subdomain:  Supporting

AHS.Cell.FinTracker
  Dominio:    Tracking de costos multi-moneda para logística
  Buyer:      CFO / Finance Director
  Conecta con: Xinfer — reacciona a PredictOkEvent (trigger de seguros)
  Subdomain:  Supporting

AHS.ControlTower.BFF
  No es una Cell — es el aggregator del Hive
  Widgets real-time (<1s): SignalR push
  Widgets analíticos (30s+): BFF + HybridCache
  BFF es READ-ONLY — nunca inicia state changes
```

---

## CÓMO INICIAR LA PRÓXIMA SESIÓN CON C1

```
1. Abre Google AI Studio — instancia C1
2. Verifica System Instructions: C1-SYSTEM-INSTRUCTIONS.md (7 skills)
3. Pega este documento como primer mensaje
4. Di: "Continuamos el desarrollo de AHS. Lee el handoff de C1
        y dime cuál es la próxima decisión de dominio."

Próxima acción de C1:
  → Validar el diseño de Xinfer V2.0 con el panel multi-agente
  → Producir Cell Canvas para AssetManager cuando Xinfer esté estable
  → Definir ADR para AHS.ControlTower.BFF (widget classification)
```

---

## ARCHIVOS RELEVANTES PARA C1

```
C1-SYSTEM-INSTRUCTIONS.md        → tus System Instructions (7 skills)
BLUEPRINT-SUPPLEMENT-V3.1.2.md   → decisiones arquitectónicas vigentes
AHS-ADR-SET-001-008.md           → 8 ADRs fundacionales
AHS-PRD-AND-TECHNOLOGY-RADAR.md  → PRDs de Xinfer, AssetManager, FinTracker
AHS-MASTER-HANDOFF.md            → visión completa del proyecto
```

---
*C1 Handoff V3.1.2 | Blueprint: V3.1.2 | Instancia: Google AI Studio C1*
