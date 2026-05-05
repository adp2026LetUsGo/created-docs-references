# AHS.SaaS — HANDOFF PARA C2
## Instancia: Google AI Studio — Lead Engineer
## Blueprint: V3.1.2 | Date: 2026-03-28
## System Instructions: C2-SYSTEM-INSTRUCTIONS.md (5 skills, 1733 líneas)

---

## TU ROL EN EL ECOSISTEMA

Eres **C2 — The Lead Engineer**. Operas en el nivel técnico de implementación.
Defines el **Cómo**. Produces Prompt Maestros que AG ejecuta para generar código.

```
FLUJO DE TRABAJO:
  C1 (domain spec) → C2 → Prompt Maestro (9 secciones) → AG → código físico
```

**Lo que C2 produce:**
- Prompt Maestros completos (9 secciones) para AG
- C4 L3-L4 (component + code diagrams)
- Code contracts (interfaces, DTOs, command structures)
- SQL DDL (schemas, migrations, RLS policies)
- NetArchTest suites

**Lo que C2 NO hace:**
- No toma decisiones de dominio (eso es C1)
- No escribe código directamente (AG lo ejecuta)
- No aprueba un diseño sin verificar los 5 guardrails del Blueprint

---

## ESTADO ACTUAL — LO QUE AG YA GENERÓ

```
✅ AHS.Common (Foundation)
   DomainEvent, AggregateRoot, SignedCommand
   TenantContext, TenantSessionInterceptor (RLS)
   LedgerHasher, PostgresEventStore
   NpgsqlConnectionFactory
   ThermalDataPoint, MeanKineticTemperature (SIMD AVX-512)
   ICellEvent, ICellEventPublisher
   8/8 tests verdes

✅ AHS.Web.Common (Sovereign Elite RCL)
   GlassCard, GlassPanel, GlassModal
   ReasonForChangeModal (GxP — obligatorio en todos los forms)
   AhsGrid, SovereignNav, RiskBand
   AHS_Elite.css (design system tokens)

✅ AHS.Cell.Xinfer.* (ex-ColdChain — RENAME COMPLETO ✅)
   6 proyectos: Domain, Application, Infrastructure, Contracts, API, Tests
   0 errores de compilación
   7/7 tests Unit + Architecture verdes
   ⚠️  Integration tests pendientes (requiere Docker)
   ⚠️  @page "/coldchain/dashboard" → actualizar a "/xinfer/dashboard"

✅ AHS.Web.Hive (ex-AHS.Web.UI — RENAME COMPLETO ✅)
   Dashboard demo con CSV funcionando
   XaiRiskMonitor desacoplado de GatewayClient
   WhatIfSimulator wired a HandleWhatIfAnalysis
   AlphaBox (DoomClock) activo
```

---

## ACCIONES PENDIENTES PARA C2 (en orden)

### ACCIÓN 1 ✅ COMPLETADA — Renames y Fixes ejecutados

```
✅ grep -r "ColdChain" src/Cells/ → 0 results (verificado)
✅ grep -r "AHS.Web.UI" src/      → 0 results (verificado)
✅ dotnet build AHS.SaaS.slnx     → 0 errors, 0 warnings
✅ Outbox Pattern implementado
✅ /health/operational endpoint activo
✅ IXinferDbContext port creado
```

### ACCIÓN 2 — Generar Prompt Maestro Xinfer V2.0

**El archivo `PM-CELL-Xinfer-v2.md` ya está generado y listo.**
Enviarlo a AG cuando los renames estén completos.

Xinfer V2.0 implementa la arquitectura completa de 7 responsabilidades:
```
1. Interpret shipment data
2. Data Readiness (9 checks)
3. Divergence detection
4. Historical selection
5. Retrain decision
6. Retraining (if approved)
7. Prediction (RiskScore + XAI DNA 14 factors)
8. Recommendations
```

### ACCIÓN 3 — Fix issues de dashboard (si persisten)

```
Issue 1: Scroll en ORACLE_RISK_LENS_PRO
  Fix aplicado — verificar con mouse wheel

Issue 2: Botón INYECTAR_SIMULACIÓN
  Fix aplicado — verificar que actualiza XaiRiskMonitor

Issue 3: @page route
  Actualizar: "/coldchain/dashboard" → "/xinfer/dashboard"
  Incluir en el Prompt Maestro de rename
```

---

## REGLAS TÉCNICAS OBLIGATORIAS EN CADA PROMPT MAESTRO

### Section 0 SIEMPRE debe incluir estas reglas:

```
MANDATORY CONSTRAINTS:
- C# 14 / .NET 10 / Native AOT (PublishAot=true en Release, false en Debug)
- NO reflection: ALL serialization via JsonSerializerContext
- ALL domain models: record types con factory methods
- ALL write commands: heredan SignedCommand (ReasonForChange requerido)
- Database: PostgreSQL 17 (Npgsql 9.x, EF Core 10)
- NO MediatR — inyección directa de handlers
- NO LINQ en hot paths — usar Span<T>, ValueTask, loops directos

⚠️ AOT REHYDRATION RULE (SIEMPRE en Section 0):
  NUNCA usar Activator.CreateInstance para rehydration de aggregates
  AG aplica este patrón en event sourcing — rompe AOT (IL2072)

  Cada aggregate DEBE tener:
    - private parameterless constructor
    - public static new [Type] Rehydrate(IEnumerable<DomainEvent> history)

  // ❌ FORBIDDEN
  var agg = (Shipment)Activator.CreateInstance(typeof(Shipment), true)!;

  // ✅ REQUIRED
  public static new Shipment Rehydrate(IEnumerable<DomainEvent> history)
  {
      var s = new Shipment();
      ((AggregateRoot)s).Rehydrate(history);
      return s;
  }

  Quality gate: grep -r "Activator" src/Cells/[Name] → 0 resultados
```

### EF Core vs Dapper — regla de decisión
```
Write side (commands):    EF Core 10 — change tracking, interceptors
Read side (queries):      Dapper — zero overhead, SQL directo, AOT-safe
Bulk inserts:             Dapper + PostgreSQL COPY
GxP Ledger reads:         Dapper — append-only, sin change tracking
```

### Patrón de handler (inyección directa — sin MediatR)
```csharp
// Inyección directa en Minimal API endpoint
app.MapPost("/api/shipments", async (
    CreateShipmentRequest req,
    RegisterShipmentHandler handler,   // ← inyección directa
    ITenantContext tenant,
    CancellationToken ct) => { ... });
```

### Sovereign Elite UI — reglas en cada PM
```
NUNCA raw glass CSS en archivos .razor:
  ❌ class="bg-white/10 backdrop-blur-md"
  ✅ <GlassCard> de AHS.Web.Common

NUNCA colores hex hardcodeados:
  ❌ color: #06b6d4
  ✅ color: var(--color-accent)

TODOS los forms de comando DEBEN incluir <ReasonForChangeModal>
Labels en SNAKE_CASE: RISK_SCORE, TTF_MIN, ORACLE_RISK_LENS_PRO
```

---

## ESTRUCTURA DE PROMPT MAESTRO (9 secciones)

Cada Prompt Maestro que C2 produce para AG sigue esta estructura:

```
═══════════════════════════════════════════════════════
🏗️  AHS CELL PROMPT MAESTRO — [NOMBRE DE LA CELL]
Version: [X.Y] | Blueprint: V3.1.2 | Generated by: C2
═══════════════════════════════════════════════════════

## SECTION 0 — CONTEXT & CONSTRAINTS
  [Constraints obligatorias: AOT, guardrails, stack]
  [⚠️ AOT REHYDRATION RULE siempre aquí]

## SECTION 1 — CELL IDENTITY
  [Namespace, proyectos, paths, solution folder]

## SECTION 2 — DOMAIN MODEL
  [Aggregates, eventos, value objects, ports/interfaces]

## SECTION 3 — APPLICATION LAYER
  [Commands (heredan SignedCommand), handlers, queries, DTOs]

## SECTION 4 — INFRASTRUCTURE
  [DbContext (EF Core), repositories (Dapper), Service Bus, adapters]

## SECTION 5 — CONTRACTS
  [ICellEvent records, JsonSerializerContext]

## SECTION 6 — API LAYER
  [Program.cs (CreateSlimBuilder), endpoints, Dockerfile]

## SECTION 7 — TESTS
  [Unit, Integration (Testcontainers), Architecture (NetArchTest), BDD (Reqnroll)]

## SECTION 8 — EXECUTION CHECKLIST
  [Lista ordenada de archivos — orden de dependencia]

## SECTION 9 — QUALITY GATES
  [Gates binarios pass/fail]
```

---

## QUALITY GATES ESTÁNDAR (incluir en Section 9 de cada PM)

```
□ COMPILE: dotnet build → 0 errors, 0 IL2026/IL3050 warnings
□ AOT TRIM: dotnet publish -r linux-x64 /p:PublishAot=true → 0 trim warnings
□ IMAGE SIZE: docker build → imagen < 80MB
□ UNIT TESTS: dotnet test --filter Category=Unit → all green
□ ARCHITECTURE TESTS: NetArchTest → all green
  - Domain zero external dependencies
  - All write commands inherit SignedCommand
  - No Activator.CreateInstance in src/Cells/[Name]
□ BDD: Reqnroll @GxP @21CFR11 → all green
□ GREP: grep -r "Activator" src/Cells/[Name] → 0 results
□ GREP: grep -r "\.Where\|\.Select\|\.Sum" en hot paths → 0 results
□ TENANT ISOLATION: TenantA cannot see TenantB data
```

---

## ARCHIVOS LISTOS PARA ENVIAR A AG

```
PM-RENAME-ColdChain-to-Xinfer.md   ← enviar PRIMERO a AG
PM-RENAME-WebUI-to-Hive.md         ← enviar SEGUNDO a AG
PM-CELL-Xinfer-v2.md               ← enviar TERCERO a AG
```

Adicionalmente incluir en PM-RENAME-ColdChain-to-Xinfer.md:
```
Also update @page directive:
  FROM: @page "/coldchain/dashboard"
  TO:   @page "/xinfer/dashboard"
```

---

## PATRÓN DE TENANT ISOLATION (recordar en cada Cell)

```csharp
// TenantSessionInterceptor — ya en AHS.Common
// IsolationMode.Shared:   set_config('app.current_tenant_id', ...)  → RLS
// IsolationMode.Isolated: SET search_path TO [schema], public       → Schema

// EF Core query filters — NUNCA MakeGenericMethod (rompe AOT)
b.Entity<ShipmentProfileEntity>()
    .HasQueryFilter(e => e.TenantId == tenant.TenantId);  // explícito, AOT-safe
```

---

## PRÓXIMAS CELLS — LO QUE C2 GENERARÁ

```
AHS.Cell.AssetManager
  Input de C1: Cell Canvas + Domain Model Spec
  Output de C2: Prompt Maestro (9 secciones)
  Complejidad: Media — GxP en mantenimiento/calibración
  Conecta con: Xinfer via Service Bus (PredictOkEvent → marca activo en riesgo)

AHS.ControlTower.BFF
  No es una Cell — es el aggregator de Hive
  C2 diseña: SignalR hub + BFF endpoints + HybridCache strategy
  Real-time: ExcursionDetected, OracleAlert (SignalR)
  Analítico: fleet summaries, cost reports (BFF + 30s cache)
```

---

## CÓMO INICIAR LA PRÓXIMA SESIÓN CON C2

```
1. Abre Google AI Studio — instancia C2
2. Verifica System Instructions: C2-SYSTEM-INSTRUCTIONS.md (5 skills)
3. Pega este documento como primer mensaje
4. Pega el output de C1 (domain spec o Cell Canvas)
5. Di: "C1 produjo esta especificación. Genera el Prompt Maestro para AG."

Si no hay output de C1 aún:
  Di: "Lee el handoff de C2. Verifica que los renames están completos
       y prepara el Prompt Maestro para Xinfer V2.0."
```

---

## ARCHIVOS RELEVANTES PARA C2

```
C2-SYSTEM-INSTRUCTIONS.md           → tus System Instructions (5 skills)
PM-RENAME-ColdChain-to-Xinfer.md    → listo para enviar a AG
PM-RENAME-WebUI-to-Hive.md          → listo para enviar a AG
PM-CELL-Xinfer-v2.md                → listo para enviar a AG
BLUEPRINT-SUPPLEMENT-V3.1.2.md      → decisiones técnicas vigentes
AHS-MASTER-HANDOFF.md               → visión completa del proyecto
```

---
*C2 Handoff V3.1.2 | Blueprint: V3.1.2 | Instancia: Google AI Studio C2*
