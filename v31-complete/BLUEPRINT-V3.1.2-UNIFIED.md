# 🛡️ AHS Universal Constitution — Blueprint V3.1.2
## The Cellular Architecture for Autonomous & Integrated Micro-SaaS
### Supersedes: Blueprint V3.1, Supplement V3.1.1, Supplement V3.1.2
### Date: 2026-03 | Status: Active

---

## 1. Vision — The AHS Cellular Manifesto

The AHS Ecosystem is a **factory of Autonomous Cells**. Each Cell is a
self-contained Micro-SaaS that can be sold as a standalone product or
plugged into **AHS Hive** — the shell that orchestrates all Cells.

```
Standalone First:   Every Cell runs, persists data, and provides value
                    without external dependencies.
AHS Compliant:      Every Cell follows Sovereign Elite UI and
                    Performance-First (Native AOT) rules.
Biological Metaphor (canonical for all AHS documentation):
  Hive            = the organism (orchestrates all Cells)
  Cells           = autonomous organs
  GxP Ledger      = immutable memory
  AOT compilation = exists without JIT dependency
  Sovereign Elite = the exoskeleton (visual identity)
```

---

## 2. The 5-Layer Skill Stack

| Layer | Name | Responsibility |
|---|---|---|
| **C1** | Runtime | .NET 10 / C# 14 / Native AOT — performance foundation |
| **C2** | Architecture | Clean Architecture + DDD + CQRS per Cell |
| **C3** | Infrastructure | Persistence per Cell (PostgreSQL 17 + Redis) |
| **C4** | Quality | NetArchTest enforces Cell boundaries — no cross-cell code leakage |
| **C5** | Context | Business vertical per Cell (logistics, finance, assets) |

---

## 3. Communication & C4 Standard

```
C4 Level 1 (Context):    Is the Cell Standalone or Integrated into Hive?
C4 Level 2 (Container):  Each Cell = independent container (API + DB)
C4 Level 3 (Component):  Cell interior follows Clean Architecture layers
C4 Level 4 (Code):       Domain types, aggregate roots, domain events
```

**Inter-Cell communication:** Azure Service Bus only.
No Cell makes direct HTTP calls to another Cell's API.
AHS Hive (via BFF) is the only exception — reads Cell APIs for display only,
never initiates state changes.

---

## 4. Cellular Namespace Hierarchy

```
AHS.Cell.[Name].Domain          Core of the Micro-SaaS.
                                Pure logic, immutable records, zero dependencies.

AHS.Cell.[Name].Application     Use cases.
                                Commands (inherit SignedCommand), queries, handlers.

AHS.Cell.[Name].Infrastructure  Adapter implementations.
                                EF Core (writes), Dapper (reads), Service Bus, Redis.

AHS.Cell.[Name].Contracts       Public events for inter-Cell communication.
                                ICellEvent records. No domain dependencies.

AHS.Cell.[Name].API             Minimal API, Native AOT, JsonSerializerContext.

AHS.Cell.[Name].Tests           xUnit, Testcontainers, NetArchTest, Reqnroll.

AHS.Common                      Cross-cutting utilities ONLY:
                                SHA256/HMAC sealing, SIMD engines,
                                TenantContext, SignedCommand, GxP Ledger,
                                ICellEvent, ICellEventPublisher.

AHS.Web.Common                  Sovereign Elite RCL:
                                GlassCard, AhsGrid, ReasonForChangeModal,
                                SovereignNav, RiskBand, AHS_Elite.css.

AHS.Web.Hive                    The shell. Orchestrates all Cells.
                                Contains BFF, SignalR hubs, dashboard layouts.
```

---

## 5. Architectural Guardrails (non-negotiable)

### G1 — Native AOT
```
No runtime reflection. All serialization via JsonSerializerContext.
No Activator.CreateInstance — aggregate rehydration via static factory:

  public static new [Aggregate] Rehydrate(IEnumerable<DomainEvent> history)
  {
      var a = new [Aggregate]();          // private constructor
      ((AggregateRoot)a).Rehydrate(history);
      return a;
  }

No MediatR (reflection-based). Explicit handler injection only.
No LINQ in hot paths — use Span<T>, stackalloc, direct loops.
CI gate: dotnet publish /p:PublishAot=true → 0 trim warnings (IL2026, IL3050).
```

### G2 — Sovereign Elite UI
```
All Cell UIs use AHS.Web.Common components — never raw glass CSS.
  ❌ class="bg-white/10 backdrop-blur-md"
  ✅ <GlassCard> from AHS.Web.Common

Never hardcode hex colors — use CSS variables from AHS_Elite.css.
  ❌ color: #06b6d4
  ✅ color: var(--color-accent)

If a Cell is sold standalone → uses its own console (same Sovereign Elite).
If a Cell is integrated into Hive → embeds into the Hive shell,
preserving the same colors, typography, and glassmorphism tokens.

Design tokens (AHS_Elite.css):
  --color-bg:      #020617   (near black)
  --color-accent:  #06b6d4   (cyan-500)
  --color-alert:   #ef4444   (red-500)
  --color-warn:    #f59e0b   (amber-500)
  --color-ok:      #10b981   (emerald-500)
  --font-mono:     JetBrains Mono
  --font-ui:       Space Grotesk
```

### G3 — Database-per-Cell
```
No Cell reads another Cell's database. Communication via API or Events only.
Each Cell owns its PostgreSQL database with Row-Level Security (RLS).

Tiered Isolation (ADR-001):
  Default (Shared):    RLS via set_config per Cell DB — N databases total
  Enterprise upgrade:  Schema-per-tenant (IsolationMode.Isolated)
                       Config change only — zero code change required

TenantContext carries IsolationMode from day 1:
  IsolationMode.Shared   → set_config('app.current_tenant_id', ...)
  IsolationMode.Isolated → SET search_path TO [schema], public
```

### G4 — GxP Integrity
```
Every state-changing command in every Cell inherits SignedCommand.
ReasonForChange is mandatory — validated in constructor.
Every write is sealed in the immutable GxP Ledger (SHA256 hash chain + HMAC).
REVOKE UPDATE, DELETE on ledger tables.
Every Cell UI form includes <ReasonForChangeModal>.
```

### G5 — Inter-Cell via Service Bus Only
```
No direct HTTP calls between Cells.
Topic naming: ahs.[cellname].events
Subscription: [consumercell]-sub
Outbox Pattern for reliable delivery (atomic with DB transaction).
AHS Hive BFF is the only component that reads Cell APIs via HTTP
(display only — never initiates state changes).
```

---

## 6. Predictive Power (per Cell)

```
Every Cell should include an inference or predictive engine.
The engine must be:
  - Native AOT compatible (no ML.NET reflection-heavy paths)
  - Explainable (XAI — output includes reasoning, not just score)
  - GxP-auditable (prediction sealed in Ledger with ReasonForChange)

Examples by domain:
  Logistics Cell   → Excursion risk prediction (Oracle REQ-001)
  Asset Cell       → Predictive maintenance (usage + time + conditions)
  Finance Cell     → Cost anomaly detection (multi-currency variance)
```

---

## 7. Naming Framework (Constitutional — applies to all Cells)

### Namespace convention

| Component Type | Pattern | Note |
|---|---|---|
| Cell projects | `AHS.Cell.[Name].[Layer]` | Name = domain capability, not sector |
| Shell | `AHS.Web.Hive` | Fixed — single organism |
| UI library | `AHS.Web.Common` | Fixed — design system |
| Foundation | `AHS.Common` | Fixed — cross-cutting |
| BFF | `AHS.ControlTower.BFF` | Fixed — aggregation layer |

### Cell naming rules
```
1. Name must express DOMAIN CAPABILITY, not industry sector
   ❌ "ColdChain" → describes the physical medium
   ✅ "Xinfer"    → describes the capability (Excursion Inference)

2. Name must be independently meaningful
   A customer buying ONLY this Cell must understand its value
   from the name alone — without knowing other Cells exist.

3. Name must be pronounceable in English, Spanish, and Italian.

4. Product name (commercial) may differ from technical namespace:
   Technical: AHS.Cell.[Name]   Commercial: AHS [ProductName]
```

### Rename protocol
```
When a Cell is renamed:
1. C2 produces: PM-RENAME-[OldName]-to-[NewName].md
2. AG executes: namespaces, folders, csproj, slnx, Dockerfile, routes
3. Update: AHS-CELL-CATALOG.md (NOT this Blueprint)
4. Commit: "refactor: [OldName]→[NewName] per naming framework"
The Blueprint is NOT modified when a Cell is renamed.
```

---

## 8. Control Tower — AHS Hive Architecture

```
AHS Hive is the shell that orchestrates all Cells.
"The hive functions even if individual cells die." (scale-to-zero)

BFF Pattern (AHS.ControlTower.BFF):
  Real-time widgets (<1s):    SignalR push from BFF → Blazor components
  Analytical widgets (30s+):  BFF → Cell API → HybridCache

Widget classification determines data strategy:
  Critical (SignalR):   active excursions, live alerts, oracle warnings
  Analytical (Cache):   fleet lists, cost summaries, compliance reports

BFF rules:
  READ-ONLY — never initiates state changes
  All state changes go directly to Cell APIs from Blazor
  Tenant context preserved via Entra ID token flow
```

---

## 9. Pre-Cell Verification Checklist

Before C2 writes the first Prompt Maestro for AG, verify:

```
□ TenantContext includes IsolationMode (Shared/Isolated) and SchemaName
□ TenantSessionInterceptor handles both modes (set_config vs SET search_path)
□ EF Core migrations have no hardcoded schema names
□ Tenant onboarding script documented

□ AHS.ControlTower.BFF exists in solution structure
□ Widget Classification table agreed (real-time vs analytical)
□ Service Bus topic + subscription configured in docker-compose

□ AHS.Web.Common exists with: GlassCard, AhsGrid, ReasonForChangeModal
□ PR template committed with Sovereign Elite checklist
□ Team agreement: new glass components go to AHS.Web.Common first

ALL BOXES CHECKED → Safe to start writing Cell code.
```

---

## 10. Approved Tech Stack

```
Language:     C# 14 / .NET 10 LTS
Compilation:  Native AOT — Release (linux-x64, Azure Container Apps)
              JIT — Debug (win-x64, local development)
Database:     PostgreSQL 17 (Npgsql 9.x)
Write ORM:    EF Core 10 (change tracking, TenantSessionInterceptor)
Read ORM:     Dapper (zero overhead, hot paths, AOT-safe)
Cache:        HybridCache .NET 10 (L1 IMemoryCache + L2 Redis 7)
Messaging:    Azure Service Bus (inter-cell only)
Auth:         Microsoft Entra ID (OIDC, custom claims, ahs_role)
UI:           Blazor .NET 10 Auto + Tailwind CSS 4
Deployment:   Azure Container Apps (scale-to-zero, minReplicas: 0)
Secrets:      Azure Key Vault (Managed Identity)
IaC:          Azure Bicep (Cell modules pattern)
Testing:      xUnit + FluentAssertions + NSubstitute + Testcontainers
BDD:          Reqnroll (@GxP @21CFR11 @REQ-001)
Architecture: NetArchTest.eNet

NOT APPROVED (do not use):
  MediatR           → reflection, breaks AOT
  AutoMapper         → reflection, use Mapperly
  SQL Server         → replaced by PostgreSQL (ADR-004)
  EF Core lazy load  → breaks AOT
  Hangfire           → reflection-based, use BackgroundService
```

---

## 11. ADR Index (Architecture Decision Records)

| ADR | Decision | Status |
|---|---|---|
| ADR-001 | Database-per-Cell + Tiered Isolation (RLS default, Schema-per-tenant for enterprise) | Accepted |
| ADR-002 | Native AOT as default compilation target | Accepted |
| ADR-003 | Azure Service Bus as sole inter-Cell channel | Accepted |
| ADR-004 | PostgreSQL over SQL Server | Accepted |
| ADR-005 | HybridCache as standard caching strategy | Accepted |
| ADR-006 | SignedCommand mandatory for ALL Cells (universal GxP) | Accepted |
| ADR-007 | Cell Contracts versioning — append-only | Accepted |
| ADR-008 | Sovereign Elite UI — AHS.Web.Common as component boundary | Accepted |

Full ADR text: `AHS-ADR-SET-001-008.md`

---

## 12. Cell Inventory

Current and planned Cells are maintained in `AHS-CELL-CATALOG.md`.
This Blueprint does not enumerate specific Cells — it defines the rules
that govern any Cell, present or future.

```
To add a new Cell:
  1. Run Cell Viability Test (5 criteria — see below)
  2. Create Cell Canvas (C1 produces)
  3. Run multi-agent panel (Architect + Domain Expert + Devil's Advocate)
  4. C2 produces Prompt Maestro (9 sections)
  5. AG generates code
  6. Register Cell in AHS-CELL-CATALOG.md

Cell Viability Test (score 3+/5 to proceed):
  □ Has its own Ubiquitous Language
  □ Could be sold standalone as Micro-SaaS
  □ Has its own data lifecycle
  □ Has its own regulatory scope
  □ Has a distinct buyer persona
```

---
*AHS Universal Constitution — Blueprint V3.1.2*
*Supersedes: Blueprint V3.1 + Supplement V3.1.1 + Supplement V3.1.2*
*This document is the single source of architectural truth.*
*The only document that should change this Blueprint is a new ADR.*
*Cell-specific information belongs in AHS-CELL-CATALOG.md*
