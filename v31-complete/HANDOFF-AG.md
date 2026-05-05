# AHS.SaaS — HANDOFF PARA AG (ANTIGRAVITY)
## Instancia: Antigravity IDE — Executor
## Blueprint: V3.1.2 | Date: 2026-03-28
## Workspace: C:\Users\armando\Documents\_AHS\projects\AHS.SaaS

---

## TU ROL EN EL ECOSISTEMA

Eres **AG — The Executor**. Generas archivos físicos de código en el proyecto.
Recibes Prompt Maestros de C2 y los ejecutas produciendo código production-ready.

```
FLUJO DE TRABAJO:
  C2 (Prompt Maestro) → AG → archivos físicos en AHS.SaaS
```

**Lo que AG hace:**
- Genera proyectos, clases, interfaces, tests, SQL, Dockerfiles, scripts
- Ejecuta renames de namespaces, proyectos y carpetas
- Corrige errores de compilación cuando se le reportan

**Lo que AG NO hace:**
- No toma decisiones de arquitectura (esas vienen en el PM)
- No modifica lógica existente si no se lo piden explícitamente
- No regenera componentes que ya existen (verificar antes)

---

## ESTADO ACTUAL DEL PROYECTO

### Ruta base
```
C:\Users\armando\Documents\_AHS\projects\AHS.SaaS\
```

### Lo que ya existe (NO regenerar)
```
src/Foundation/AHS.Common/                    ✅ COMPLETO — no tocar
src/Foundation/AHS.Web.Common/                ✅ COMPLETO — no tocar
src/Cells/Xinfer/                             ✅ RENAME COMPLETO
src/Presentation/AHS.Web.Hive/                ✅ RENAME COMPLETO

Componentes UI que NO debes regenerar jamás:
  AlphaBox.razor          → Doom Clock (TTF countdown)
  AuditLedger.razor       → GxP Ledger table SHA256
  WhatIfSimulator.razor   → PRE-FLIGHT_RISK_SIMULATOR
  DeltaTChart.razor       → THERMAL_PROJECTION_T+30
  TelemetryHud.razor      → footer HUD SIMD
  XaiDiagnostic.razor     → XAI DNA panel
  XaiRiskMonitor.razor    → risk percentage widget
```

### Tests actuales
```
AHS.Common.Tests:       8/8 verdes ✅
AHS.Cell.Xinfer.Tests:  7/7 Unit + Architecture verdes ✅
Integration tests:      ⚠️  pendientes — requieren Docker activo
```

---

## ACCIONES PENDIENTES — EJECUTAR EN ESTE ORDEN

### PASO 1 — git checkpoint (antes de cualquier cosa)
```powershell
cd C:\Users\armando\Documents\_AHS\projects\AHS.SaaS
git add .
git commit -m "chore: pre-rename checkpoint — V3.1.2"
```

### PASO 2 — Rename ColdChain → Xinfer
```
Archivo: PM-RENAME-ColdChain-to-Xinfer.md
Instrucción adicional (NO está en el archivo — agregar):
  Also update @page directive in ColdChainDashboard.razor:
    FROM: @page "/coldchain/dashboard"
    TO:   @page "/xinfer/dashboard"

Verificación post-rename:
  dotnet build AHS.SaaS.slnx → 0 errors
  grep -r "ColdChain" src/Cells/ → 0 results
  grep -r "XaiDiagnostic" . → results exist (NO se renombra)
```

### PASO 3 — Rename AHS.Web.UI → AHS.Web.Hive
```
Archivo: PM-RENAME-WebUI-to-Hive.md

Verificación post-rename:
  dotnet build AHS.SaaS.slnx → 0 errors
  grep -r "AHS\.Web\.UI" src/ → 0 results
  grep -r "AHS\.Web\.Hive" src/ → results exist

Commit:
  git commit -m "refactor: Xinfer + Hive naming (Blueprint V3.1.2)"
```

### PASO 4 — Implementar Xinfer V2.0
```
Archivo: PM-CELL-Xinfer-v2.md

Esta es la arquitectura completa de 7 responsabilidades.
Implementa las 7 responsabilidades autónomas de Xinfer sobre el chassis ya existente.
Lee COMPLETO Section 0 antes de generar el primer archivo.

Verificación:
  dotnet build → 0 errors
  dotnet test --filter Category=Unit → all green
  dotnet test --filter Category=Architecture → all green
  grep -r "Activator" src/Cells/Xinfer → 0 results
```

### PASO 5 — Fix issues de dashboard (si persisten)
```
Issue 1: Scroll en ORACLE_RISK_LENS_PRO
  Causa probable: overflow:hidden en contenedor padre
  Fix: max-height + overflow-y:auto en wrapper de tabla

Issue 2: Botón INYECTAR_SIMULACIÓN sin acción
  Causa probable: OnAnalyze no bindeado en ColdChainDashboard.razor
  Fix: <WhatIfSimulator OnAnalyze="HandleWhatIfAnalysis" />

Issue 3: WhatIfSimulator desaparecido
  Causa probable: AG sobrescribió el componente al añadir [Parameter]
  Fix: restaurar markup original, solo añadir los [Parameter] necesarios

REGLA AL MODIFICAR COMPONENTES EXISTENTES:
  "Only modify the specific lines mentioned.
   Do NOT rewrite or regenerate the entire component.
   Preserve all existing markup exactly as-is."
```

### PASO 6 — Integration tests con Docker
```
Cuando Docker Desktop esté activo:
  dotnet test tests/Cells/Xinfer/ --filter Category=Integration

Test crítico de seguridad:
  TenantIsolationTests — TenantA no puede ver datos de TenantB
  DEBE pasar antes de cualquier deployment a producción
```

---

## REGLAS CRÍTICAS — LEER ANTES DE GENERAR CUALQUIER ARCHIVO

### 1. Native AOT — Regla de Rehydration (aprendida en producción)
```
❌ NUNCA usar Activator.CreateInstance para rehydration de aggregates
   AG aplica esto frecuentemente en event sourcing — ROMPE AOT (IL2072)

✅ SIEMPRE usar static factory:
public static new Shipment Rehydrate(IEnumerable<DomainEvent> history)
{
    var s = new Shipment();          // private constructor
    ((AggregateRoot)s).Rehydrate(history);
    return s;
}

Verificación obligatoria: grep -r "Activator" src/Cells/[Name] → 0 results
```

### 2. JsonSerializerContext — obligatorio
```
❌ NUNCA: JsonSerializer.Serialize(obj)  sin JsonTypeInfo<T> explícito
✅ SIEMPRE: JsonSerializer.Serialize(obj, CellJsonContext.Default.TypeName)

Todos los tipos que cruzan la API boundary deben estar en:
  [JsonSerializable(typeof(ShipmentDto))]
  public partial class XinferJsonContext : JsonSerializerContext { }
```

### 3. Sin MediatR
```
❌ services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(...))
✅ Inyección directa del handler en el endpoint Minimal API
```

### 4. Sin LINQ en hot paths
```
❌ factors.Select(f => f * weight).Sum()  // heap allocations
✅ Span<double> factors = stackalloc double[14];
   double total = 0; foreach (var f in factors) total += f;
```

### 5. Sovereign Elite UI
```
❌ NUNCA en archivos .razor:
   class="bg-white/10 backdrop-blur-md border-white/20"
   style="color: #06b6d4"

✅ SIEMPRE:
   <GlassCard> de AHS.Web.Common
   color: var(--color-accent)

✅ SIEMPRE en forms con OnValidSubmit:
   <ReasonForChangeModal>  ← GxP obligatorio
```

### 6. EF Core query filters — AOT safe
```
❌ NUNCA MakeGenericMethod para query filters (rompe AOT)
✅ SIEMPRE explícito por entidad:
   b.Entity<ShipmentProfileEntity>()
       .HasQueryFilter(e => e.TenantId == tenant.TenantId);
```

---

## ARCHIVOS PROMPT MAESTRO (en orden de ejecución)

```
1. PM-RENAME-ColdChain-to-Xinfer.md   ← EJECUTAR PRIMERO
2. PM-RENAME-WebUI-to-Hive.md         ← EJECUTAR SEGUNDO
3. PM-CELL-Xinfer-v2.md               ← EJECUTAR TERCERO

Ya ejecutados (referencia):
  PM-FOUNDATION-AHS-Common-WebCommon.md  ✅
  PM-CELL-ColdChain.md                   ✅ (supersedido por Xinfer v2)
  PM-DASHBOARD-ColdChain-Demo.md         ✅
```

---

## SOLUTION STRUCTURE (referencia)

```
AHS.SaaS.slnx
├── 📁 Foundation
│   ├── AHS.Common              → src/Foundation/AHS.Common/
│   └── AHS.Web.Common          → src/Foundation/AHS.Web.Common/
├── 📁 Infrastructure
│   └── AHS.ControlTower.BFF    → src/Infrastructure/AHS.ControlTower.BFF/ (futuro)
├── 📁 Cells
│   └── AHS.Cell.Xinfer.*       → src/Cells/Xinfer/
│       ├── AHS.Cell.Xinfer.Domain
│       ├── AHS.Cell.Xinfer.Application
│       ├── AHS.Cell.Xinfer.Infrastructure
│       ├── AHS.Cell.Xinfer.Contracts
│       ├── AHS.Cell.Xinfer.API
│       └── AHS.Cell.Xinfer.Tests → tests/Cells/Xinfer/
└── 📁 Control Tower
    └── AHS.Web.Hive            → src/Presentation/AHS.Web.Hive/
```

---

## CÓMO LANZAR LA APLICACIÓN

```powershell
# Desde la raíz del proyecto
cd C:\Users\armando\Documents\_AHS\projects\AHS.SaaS
.\AHS_SaaS_Ignition_V5.ps1

# O manualmente:
# Terminal 1 — Xinfer API (Debug, sin AOT, win-x64)
dotnet run --project src/Cells/Xinfer/AHS.Cell.Xinfer.API/AHS.Cell.Xinfer.API.csproj `
    /p:PublishAot=false /p:RuntimeIdentifier=win-x64

# Terminal 2 — Hive UI
dotnet run --project src/Presentation/AHS.Web.Hive/AHS.Web.Hive.csproj

# URLs:
#   Xinfer API:  http://localhost:5000
#   Xinfer health: http://localhost:5000/health
#   Hive UI:     http://localhost:5120
#   Dashboard:   http://localhost:5120/xinfer/dashboard
```

**IMPORTANTE:** No usar `linux-x64` en desarrollo local — eso genera el error
"not a valid application for this OS platform".
AOT + linux-x64 solo para Release/producción (Azure Container Apps).

---

## SKILLS EN DISCO (.agent/skills/)

```
.agent\skills\
├── 00_Constitution\
│   ├── Blueprint.MD
│   ├── Blueprint_Supplement_V3.1.2.MD
│   ├── AHS-ADR-SET-001-008.md
│   └── AHS-SKILLS-DISTRIBUTION-MAP.md
├── 01_Core\
│   ├── native-aot\
│   ├── simd-vectorization-csharp\
│   ├── sha256-cryptographic-sealing\
│   └── regulatory-compliance-matrix\
├── 02_Architecture\
│   ├── ahs-cellular-architecture\
│   ├── ahs-dotnet-architect\ (versión V3.1 — reemplaza el .md anterior)
│   ├── ddd-strategic-design\
│   ├── cqrs-clean-architecture-patterns\
│   ├── cell-integration-patterns\
│   └── multi-agent-brainstorming\
├── 03_Backend\
│   ├── gxp-ledger-eventsourcing\
│   ├── industrial-cold-chain-logic\
│   ├── logistics-oracle-xai\
│   ├── ahs-testing-quality\
│   └── azure-devops-coldchain\
├── 04_UI_UX\
│   ├── blazor-razor-expert\  (versión .NET 10)
│   └── tailwind-glassmorphism-system\
└── 05_Workflow\
    ├── prompt-engineering-ag\  (incluye AOT Rehydration Rule)
    └── ahs-cell-template\
```

---
*AG Handoff V3.1.2 | Blueprint: V3.1.2 | Workspace: AHS.SaaS*
