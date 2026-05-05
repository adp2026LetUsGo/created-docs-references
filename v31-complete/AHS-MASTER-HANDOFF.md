# AHS.SaaS — MASTER HANDOFF DOCUMENT
## For: C1 (Google AI Studio) + AG (Antigravity)
## Blueprint: V3.1.2 | Date: 2026-03-28
## Status: Active Development — Ready for Cell Xinfer V2.0

---

## 1. WHAT WAS THE PROJECT BEFORE

### Original State (V1.0 — Modular Monolith)
```
Architecture:  Modular Monolith
Solution:      AHS.Micro.SaaS
Structure:     src/Presentation/AHS.Gateway.API
               src/Presentation/AHS.Web.UI
               src/Common/AHS.Common
               src/Engines/AHS.Engines.HPC
Entry point:   AHS.Gateway.API (single API for everything)
UI:            AHS.Web.UI (single Blazor app)
```

### Problems with V1.0
- Single API became a bottleneck — all logic in one place
- Could not sell individual modules independently
- No tenant isolation per domain
- GxP compliance was global, not per-Cell
- No clear boundaries between logistics, finance, and assets

---

## 2. WHAT WAS BUILT IN THIS SESSION

### Architecture Migration: Modular Monolith → Cell-Based Architecture

```
BEFORE (V1.0):                    AFTER (V3.1.2):
──────────────────────────────    ──────────────────────────────────────
AHS.Micro.SaaS (monolith)        AHS.SaaS (Cell factory)
  AHS.Gateway.API               →  AHS.Cell.Xinfer.* (6 projects)
  AHS.Web.UI                    →  AHS.Web.Hive (shell)
  AHS.Common (partial)          →  AHS.Common (complete foundation)
  AHS.Engines.HPC               →  Migrated into AHS.Common.Engines
  No tenant isolation           →  PostgreSQL RLS + IsolationMode
  No GxP everywhere             →  SignedCommand universal
  Vertical Slice (V2.0)         →  Clean Architecture + DDD + CQRS
```

### Solution Structure (current)

```
AHS.SaaS.slnx
├── 📁 Foundation
│   ├── AHS.Common              ✅ COMPLETE — 8/8 tests green
│   │   ├── Domain: DomainEvent, AggregateRoot
│   │   ├── Application: SignedCommand, ElectronicSignatureRequiredException
│   │   ├── Infrastructure: TenantContext, TenantSessionInterceptor,
│   │   │                   LedgerHasher, PostgresEventStore,
│   │   │                   NpgsqlConnectionFactory
│   │   ├── Engines: ThermalDataPoint, MeanKineticTemperature (SIMD)
│   │   └── Contracts: ICellEvent, ICellEventPublisher
│   └── AHS.Web.Common          ✅ COMPLETE — components verified
│       ├── GlassCard, GlassPanel, GlassModal
│       ├── ReasonForChangeModal (GxP — mandatory in all forms)
│       ├── AhsGrid, AhsVirtualList
│       ├── SovereignNav, CellSideNav
│       ├── RiskBand, ComplianceStatus, ExcursionBadge
│       ├── CellDashboard, CommandConsole
│       └── AHS_Elite.css (design system tokens)
│
├── 📁 Infrastructure
│   └── AHS.ControlTower.BFF    ⏳ PLANNED — not yet generated
│
├── 📁 Cells
│   └── AHS.Cell.Xinfer.*       ✅ RENAME COMPLETE + Outbox + Health
│       ├── Domain              ✅ Compiled
│       ├── Application         ✅ Compiled
│       ├── Infrastructure      ✅ Compiled
│       ├── Contracts           ✅ Compiled
│       ├── API                 ✅ Compiled (0 errors, 0 warnings)
│       └── Tests               ✅ 7/7 Unit + Architecture green
│                               ⚠️  Integration tests pending (needs Docker)
│
└── 📁 Control Tower
    └── AHS.Web.Hive            ✅ RENAME COMPLETE
        ├── XinferDashboard     ✅ Generated with CSV data
        ├── XaiRiskMonitor      ✅ Decoupled from GatewayClient
        ├── WhatIfSimulator     ✅ Wired to HandleWhatIfAnalysis
        └── AlphaBox (DoomClock) ✅ Active, pulses red on critical
```

---

## 3. NAMING DECISIONS (FINAL — DO NOT CHANGE)

```
Component              Technical Namespace      Product Name
─────────────────────  ──────────────────────── ────────────────────────
Shell/Orchestrator  →  AHS.Web.Hive             AHS Hive
Inference Cell      →  AHS.Cell.Xinfer          AHS Xinfer
Design System       →  AHS.Web.Common           Sovereign Elite
Foundation          →  AHS.Common               —

Biological metaphor (canonical for all documentation):
  AHS Hive         = the organism (orchestrates all Cells)
  Cells            = autonomous organs
  Xinfer           = the predictive nervous system
  GxP Ledger       = immutable memory
  AOT              = exists without JIT dependency
  Sovereign Elite  = the exoskeleton

Xinfer naming:
  X = Excursion (FDA/GxP term for temperature deviation event)
  Pronounced: "ex-in-fer"
  Full name: Excursion Inference Engine
  Tagline: "Predict. Explain. Prevent."
```

---

## 4. PENDING ACTIONS (execute in this exact order)

### STEP 1 — Git checkpoint (do NOW before anything else)
```powershell
cd C:\Users\armando\Documents\_AHS\projects\AHS.SaaS
git add .
git commit -m "chore: pre-rename checkpoint — V3.1.2"
```

### STEP 2 ✅ COMPLETE — Rename ColdChain → Xinfer
```
Executed: PM-RENAME-ColdChain-to-Xinfer.md
Also instruct AG to update:
  @page "/coldchain/dashboard" → @page "/xinfer/dashboard"
Verify: dotnet build → 0 errors
Verify: grep -r "ColdChain" src/Cells/ → 0 results
```

### STEP 3 ✅ COMPLETE — Rename AHS.Web.UI → AHS.Web.Hive
```
File: PM-RENAME-WebUI-to-Hive.md
Verify: dotnet build → 0 errors
Verify: grep -r "AHS\.Web\.UI" src/ → 0 results
Commit: git commit -m "refactor: Xinfer + Hive naming (Blueprint V3.1.2)"
```

### STEP 4 — Verify Google AI Studio C1 + C2 (keep both)

**C1 and C2 remain as two separate instances. Do NOT consolidate.**

Why two instances is the correct decision for AHS:
```
C1 (Architect & PM):
  → Reasons in domain language: what to build, why, for whom
  → Produces: PRDs, Cell Canvas, C4 L1-L2, ADRs, domain specs
  → Skills: ddd-strategic-design, regulatory-compliance-matrix,
            ahs-product-cell-canvas, brainstorming,
            multi-agent-brainstorming, c4-documentation-standard
  → Does NOT generate Prompt Maestros

C2 (Lead Engineer):
  → Reasons in technical language: how to build it
  → Produces: Prompt Maestros (9 sections) for AG to execute
  → Skills: cqrs-clean-architecture-patterns, cell-integration-patterns,
            prompt-engineering-ag, c4-documentation-standard (L3-L4)
  → Does NOT make domain or product decisions

Why NOT consolidate:
  → Mixing domain reasoning with technical implementation causes
    "attention drift" — Gemini loses depth in both areas
  → C1 asking "should we build this Cell?" is a different cognitive
    mode than C2 asking "how do we implement this handler?"
  → For complex Cells like Xinfer (Oracle, GxP, SIMD, XAI),
    the technical depth of C2's Prompt Maestro requires full focus
```

Action for this step:
```
C1: Verify System Instructions contain C1-SYSTEM-INSTRUCTIONS.md
    (7 skills: c1-architect-pm + brainstorming + multi-agent-brainstorming
    + ddd-strategic-design + regulatory-compliance-matrix
    + ahs-product-cell-canvas + c4-documentation-standard)

C2: Verify System Instructions contain C2-SYSTEM-INSTRUCTIONS.md
    (5 skills: c2-lead-engineer + cqrs-clean-architecture-patterns
    + cell-integration-patterns + prompt-engineering-ag
    + c4-documentation-standard)

Files: C1-SYSTEM-INSTRUCTIONS.md and C2-SYSTEM-INSTRUCTIONS.md
       (both in v31-complete/ outputs)
```

### STEP 4 ✅ COMPLETE — Outbox Pattern + Operational Health
```
Executed: PM-FIX-Xinfer-Outbox-Health.md
Delivered: IXinferDbContext port, IOutboxWriter, OutboxPublisherService,
           /health/operational endpoint, XinferLifecycleState
Commit: "feat: Outbox Pattern + Operational Health + IXinferDbContext port"
```

### STEP 5 — Implement Xinfer V2.0 (NEXT ACTION)
```
File: PM-CELL-Xinfer-v2.md
This replaces the simple ColdChain cell with the full
7-responsibility autonomous Xinfer architecture
```

### STEP 6 — Fix dashboard issues (if still present)
```
□ Scroll in ORACLE_RISK_LENS_PRO grid
□ INYECTAR_SIMULACIÓN button wiring
□ WhatIfSimulator visibility
```

### STEP 7 — Run integration tests (when Docker is active)
```
dotnet test tests/Cells/Xinfer/ --filter Category=Integration
Critical: TenantIsolationTests must pass before any production deployment
```

---

## 5. XINFER CELL — ARCHITECTURE DETAIL

### The 7 Responsibilities (strictly ordered)

```
EXECUTION ORDER (enforced by domain invariant):
  1. Interpret shipment data      → ShipmentIdentity + CarrierProfile
  2. Data Readiness validation    → 9 checks → Acceptable|Risky|NotAcceptable
  3. Divergence detection         → route, carrier, packaging, season
  4. Historical selection         → compatible records, outlier removal
  5. Retrain decision             → 6 criteria evaluated
  6. Retraining (if approved)     → ModelVersion(n+1)
  7. Prediction                   → RiskScore + XAI DNA 14 factors
  8. Recommendations              → actionable, GxP-auditable rules

CRITICAL RULE:
  Prediction MUST NEVER execute before Data Readiness.
  Enforced by: XinferSequenceViolationException
  If AG generates code violating this order → Architecture Test fails.
```

### Key Domain Rules
```
1. Carrier = risk modifier, NOT shipment identity
   ShipmentIdentity = Product + Route + PackagingType + DepartureDate
   Same shipment, different carrier = same ID, different risk score

2. XAI DNA = exactly 14 diagnostic factors (no more, no less)
   Quality gate: PredictionResultDto.XaiDna.Factors.Count == 14

3. Passive insulation = +15% base penalty (Blueprint REQ-001)
   if PackagingType == "PassiveChamber": baseScore *= 1.15

4. Pessimistic TTF = PhysicalTtf × (1 - riskScore/100 × 0.60)
   Safe window = PessimisticTtf × 0.80

5. Data Readiness blocks prediction:
   Pharmaceutical + PassiveChamber + duration > 48h → ERROR (not warning)
   Dataset < 5 records → ERROR (blocks prediction entirely)
```

### 4 Input Adapters
```
Local    → CSV/Excel from wwwroot/data/ (current demo mode)
Azure    → Azure Blob Storage / Event Hub
OCI      → Oracle Cloud Infrastructure Object Storage
Firebase → Firebase Realtime Database / Firestore

Selected via: config["Xinfer:InputAdapter"] — switch expression (AOT-safe)
```

### Contracts (published events to Service Bus)
```
Topic: ahs.xinfer.events
Events:
  READINESS_OK    → ReadinessOkEvent
  READINESS_FAIL  → ReadinessFailEvent
  RETRAIN_REQUIRED → RetrainRequiredEvent
  PREDICT_OK      → PredictOkEvent
```

---

## 6. TECHNICAL CONSTRAINTS (non-negotiable)

```
Language:     C# 14 / .NET 10 LTS
Compilation:  Native AOT for Release (linux-x64, Azure)
              JIT for Debug (win-x64, local development)
Database:     PostgreSQL 17 (Npgsql 9.x)
Write ORM:    EF Core 10 (change tracking, TenantSessionInterceptor)
Read ORM:     Dapper (zero overhead, hot paths)
Cache:        HybridCache .NET 10 (L1 IMemoryCache + L2 Redis)
Messaging:    Azure Service Bus (inter-cell only — no direct HTTP)
Auth:         Microsoft Entra ID
Testing:      xUnit + FluentAssertions + NSubstitute + Testcontainers
BDD:          Reqnroll (@GxP @21CFR11 @REQ-001)
```

### AOT Critical Rules
```
✅ ALL serialization via JsonSerializerContext source generators
✅ ALL aggregate rehydration via static Rehydrate() factory
✅ NO Activator.CreateInstance (breaks AOT — IL2072)
✅ NO MediatR (uses reflection)
✅ NO LINQ in hot paths (PredictionEngine, scoring loops)
✅ Span<T> + stackalloc for ≤14 element arrays
✅ ValueTask for cached results
```

---

## 7. UI/DESIGN SYSTEM

### Sovereign Elite (AHS_Elite.css)
```css
--color-bg:      #020617   /* near black background */
--color-accent:  #06b6d4   /* cyan-500 */
--color-alert:   #ef4444   /* red-500 — critical */
--color-warn:    #f59e0b   /* amber-500 — elevated */
--color-ok:      #10b981   /* emerald-500 — nominal */
--font-mono:     JetBrains Mono
--font-ui:       Space Grotesk
```

### UI Rules (enforced by NetArchTest)
```
NEVER raw glass CSS in .razor files
  ❌ class="bg-white/10 backdrop-blur-md"
  ✅ <GlassCard> from AHS.Web.Common

NEVER hardcode hex colors
  ❌ color: #06b6d4
  ✅ color: var(--color-accent)

EVERY command form MUST include <ReasonForChangeModal>
Labels in SNAKE_CASE (operator vocabulary: RISK_SCORE, TTF_MIN)
```

### Existing Components (DO NOT REGENERATE)
```
AlphaBox.razor          → Doom Clock (TTF countdown)
AuditLedger.razor       → GxP Ledger table with SHA256
WhatIfSimulator.razor   → PRE-FLIGHT_RISK_SIMULATOR
DeltaTChart.razor       → THERMAL_PROJECTION_T+30
TelemetryHud.razor      → bottom HUD: ENGINE: SIMD_AVX-512_ENABLED
XaiDiagnostic.razor     → XAI DNA panel (14 factors)
XaiRiskMonitor.razor    → risk percentage widget
```

---

## 8. CURRENT KNOWN ISSUES

```
Issue 1: Scroll in ORACLE_RISK_LENS_PRO grid
  Status: Fix was applied by AG but needs verification
  Test: Mouse wheel should scroll table rows

Issue 2: INYECTAR_SIMULACIÓN button
  Status: EventCallback wiring was fixed by AG
  Test: Click button → XaiRiskMonitor updates → AuditLedger gets new entry

Issue 3: Integration tests blocked
  Status: Tests exist but Docker daemon not running
  Action: Run when Docker Desktop is active
  Command: dotnet test --filter Category=Integration

Issue 4: @page route needs update
  Status: Pending with rename
  Current: @page "/coldchain/dashboard"
  Target:  @page "/xinfer/dashboard"
```

---

## 9. FILES READY IN v31-complete/ (use these with AG)

```
PM-RENAME-ColdChain-to-Xinfer.md      ← send to AG FIRST
PM-RENAME-WebUI-to-Hive.md            ← send to AG SECOND
PM-CELL-Xinfer-v2.md                  ← send to AG THIRD (new Xinfer architecture)
PM-FOUNDATION-AHS-Common-WebCommon.md ← already executed ✅
PM-CELL-ColdChain.md                  ← already executed ✅ (superseded by Xinfer v2)
PM-DASHBOARD-ColdChain-Demo.md        ← already executed ✅
C1-SYSTEM-INSTRUCTIONS.md             ← paste into Google AI Studio C1 (1582 lines — 7 skills concatenated)
                                         NOTE: NOT the same as SYSTEM-INSTRUCTIONS-C1-Architect-PM.md
                                         That file is a single skill for AG disk only
C2-SYSTEM-INSTRUCTIONS.md             ← paste into Google AI Studio C2 (1733 lines — 5 skills concatenated)
BLUEPRINT-SUPPLEMENT-V3.1.2.md        ← save to 00_Constitution\
AHS-ADR-SET-001-008.md                ← save to 00_Constitution\
AHS-SKILLS-DISTRIBUTION-MAP.md        ← save to 00_Constitution\
AHS-PRD-AND-TECHNOLOGY-RADAR.md       ← save to docs\
AHS_SaaS_Ignition_V5.ps1              ← run from project root
POST-RENAME-BLUEPRINT-STATE.md        ← reference for next session
```

---

## 10. HOW TO START THE NEXT SESSION

### With Claude (new chat)
```
Paste this document at the start of the conversation.
Say: "Continue from the AHS handoff document."
Claude has access to the full transcript at:
  /mnt/transcripts/[session-file].txt
```

### With C1 (Google AI Studio — Architect & PM)
```
System Instructions: C1-SYSTEM-INSTRUCTIONS.md (7 skills)
Role: receives business requirements → produces domain specs + Cell Canvas
First message: paste this handoff document
Say: "We are continuing AHS development. Read the handoff and
      tell me what the next domain decision is."
```

### With C2 (Google AI Studio — Lead Engineer)
```
System Instructions: C2-SYSTEM-INSTRUCTIONS.md (5 skills)
Role: receives C1 domain spec → produces Prompt Maestro for AG
First message: paste C1's output + this handoff document
Say: "C1 produced this spec. Generate the Prompt Maestro for AG."
```

### With AG (Antigravity)
```
1. Verify AHS.SaaS project is open
2. Run git commit checkpoint first
3. Send PM-RENAME-ColdChain-to-Xinfer.md
4. Wait for 0 errors confirmation
5. Send PM-RENAME-WebUI-to-Hive.md
6. Send PM-CELL-Xinfer-v2.md
```

### Launch the application
```powershell
cd C:\Users\armando\Documents\_AHS\projects\AHS.SaaS
.\AHS_SaaS_Ignition_V5.ps1
```

---

## 11. NEXT CELLS (future roadmap)

```
After Xinfer V2.0 is stable:

AHS.Cell.AssetManager    → GxP asset lifecycle management
                           Reacts to: Xinfer.PredictOkEvent (marks asset at risk)

AHS.Cell.FinTracker      → multi-currency logistics cost tracking
                           Reacts to: Xinfer.PredictOkEvent (insurance trigger)

AHS.ControlTower.BFF     → real-time aggregation for Hive dashboard
                           SignalR for: ExcursionDetected, OracleAlert
                           HybridCache for: analytical widgets (30s TTL)

.NET Aspire              → introduce when 2+ Cells are active
                           AHS.AppHost orchestrates all services locally
```

---
*Generated: 2026-03-28 | Blueprint V3.1.2 | Session: AHS Master Build*
*Transcript available for full context recovery*
