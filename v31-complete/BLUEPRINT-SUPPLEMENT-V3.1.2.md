# AHS Blueprint Supplement V3.1.2
## Resolution of Three Architectural Tensions + Constitutional Naming Framework
## Prerequisite reading before writing the first line of Cell code

**Status**: Accepted — supersedes ambiguities in Blueprint V3.1
**Date**: 2025-Q1
**Replaces open questions in**: ADR-001, ADR-008, inter-Cell data access

---

## Tension 1 Resolution — Database-per-Cell + Multitenancy

### Decision: Tiered Isolation Model (Flexible Path)

The answer to "most flexible without migration" is a **two-tier model with a config flag** — not a fixed choice between RLS or physical isolation, but an architecture that supports both without rewriting code.

```
TenantContext carries IsolationMode:
  - Shared (default): all tenants in the Cell's single DB, RLS enforces isolation
  - Isolated (enterprise): tenant has its own schema within the Cell's DB
```

### Implementation

**Phase 1 — Ship now (all tenants)**

```
AHS.Cell.[Name] → 1 PostgreSQL DB: ahs_[name]
  ├── public schema (default) — shared by all Shared-mode tenants
  ├── [future] pharma_corp_eu schema — Isolated-mode tenant
  └── [future] biglogistics_us schema — Isolated-mode tenant
```

```csharp
// TenantContext extended — carry isolation mode from day 1
public record TenantContext : ITenantContext
{
    public Guid          TenantId      { get; init; }
    public string        TenantSlug    { get; init; } = "";
    public TenantPlan    Plan          { get; init; }
    public IsolationMode IsolationMode { get; init; } = IsolationMode.Shared;
    public string        SchemaName    { get; init; } = "public"; // "public" for Shared
}

public enum IsolationMode { Shared, Isolated }
```

```csharp
// TenantSessionInterceptor — handles both modes with zero code change later
public class TenantSessionInterceptor(ITenantContext tenant) : DbCommandInterceptor
{
    public override async ValueTask<InterceptionResult<DbDataReader>> ReaderExecutingAsync(
        DbCommand command, CommandEventData _, InterceptionResult<DbDataReader> result, CancellationToken ct)
    {
        await using var setCmd = command.Connection!.CreateCommand();
        setCmd.Transaction = command.Transaction;

        if (tenant.IsolationMode == IsolationMode.Isolated)
        {
            // Switch schema for this session — Isolated tenant gets their own schema
            setCmd.CommandText = $"SET search_path TO {tenant.SchemaName}, public";
            await setCmd.ExecuteNonQueryAsync(ct);
        }
        else
        {
            // Shared mode — RLS via set_config
            setCmd.CommandText = "SELECT set_config('app.current_tenant_id', @tid, true)";
            setCmd.Parameters.Add(new NpgsqlParameter("tid", tenant.TenantId.ToString()));
            await setCmd.ExecuteNonQueryAsync(ct);
        }

        return result;
    }
}
```

**Phase 2 — First enterprise tenant (config, not code)**

```sql
-- When onboarding an enterprise tenant:
-- 1. Create their schema
CREATE SCHEMA pharma_corp_eu;

-- 2. Run Cell migrations in their schema
SET search_path TO pharma_corp_eu;
-- [run same EF Core migration SQL]

-- 3. Update tenant record in registry
UPDATE tenants SET isolation_mode = 'Isolated', schema_name = 'pharma_corp_eu'
WHERE tenant_slug = 'pharma-corp-eu';
```

```csharp
// No application code changes. TenantSessionInterceptor already handles this.
// Entra ID claim "isolation_mode" added to tenant's app registration.
```

### Cost Model

```
Shared tenants (default):
  1 PostgreSQL DB per Cell × N Cells
  Example: 4 Cells = 4 DBs regardless of tenant count
  Azure cost: ~€15/month per Cell (serverless, autopause)

Isolated tenants (enterprise):
  1 schema per enterprise tenant within each Cell's DB
  Additional cost per enterprise tenant: ~€0 (schemas are free in PostgreSQL)
  Enterprise pricing: justify with compliance premium (€X/month extra)
  
If an enterprise tenant requires a physically separate DB (separate Azure server):
  They pay for their own Azure Flexible Server instance
  You manage it, they fund it — contractual SLA upgrade
```

### What C2 Must Do Differently from Day 1

```
✅ TenantContext must carry IsolationMode and SchemaName from the first Cell
✅ TenantSessionInterceptor must handle both modes (copy the implementation above)
✅ All EF Core migrations must be schema-agnostic (no hardcoded schema names)
✅ NetArchTest: verify no migration uses hardcoded "public" schema reference
✅ Tenant onboarding script: creates schema + runs migrations + updates registry
❌ Do NOT create N×M databases now — that's the nuclear option for the future
❌ Do NOT assume all tenants are always in "public" schema
```

---

## Tension 2 Resolution — Control Tower Data Aggregation

### Decision: BFF (Backend for Frontend) with SignalR for Critical Widgets

The Control Tower serves **two fundamentally different widget types**. The architecture must serve both without compromise:

```
Critical widgets (real-time < 1s):
  Active excursions, live sensor readings, Oracle alerts, circuit breakers
  → SignalR push from Cell → BFF → CT (Blazor component subscribes)

Analytical widgets (near real-time, seconds-minutes OK):
  Shipment history, cost summaries, asset status, compliance reports
  → HTTP + HybridCache from BFF → Cell APIs
```

### BFF Architecture

```
AHS.Web.UI (Blazor)
    ↓ Blazor component calls
AHS.ControlTower.BFF  ← NEW project (Minimal API, AOT-safe)
    ├── /bff/[cellname]/* → HTTP → AHS.Cell.[Name].API (+ cache)
    ├── /bff/assetmgr/*   → HTTP → AHS.Cell.AssetManager.API (+ cache)
    ├── /bff/fintracker/* → HTTP → AHS.Cell.FinTracker.API (+ cache)
    └── /bff/realtime     → SignalR hub (subscribes to Service Bus)
                              pushes to Blazor clients
```

```csharp
// AHS.ControlTower.BFF/Hubs/CellEventHub.cs
// SignalR hub — receives Service Bus events, pushes to connected CT clients
public class CellEventHub(IHubContext<CellEventHub> hub) : Hub
{
    // Called by Service Bus consumer when excursion detected
    public async Task BroadcastExcursionAsync(ShipmentExcursionDetected evt)
    {
        // Push only to clients of the correct tenant
        await hub.Clients.Group(evt.TenantSlug)
            .SendAsync("ExcursionDetected", evt);
    }
}

// Service Bus consumer in BFF — subscribes to all Cell topics
public class BffEventConsumer(ServiceBusClient sb, IHubContext<CellEventHub> hub)
    : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        var processor = sb.CreateProcessor("ahs.coldchain.events",
            "controltower-sub",
            new ServiceBusProcessorOptions { MaxConcurrentCalls = 4 });

        processor.ProcessMessageAsync += async args =>
        {
            // Deserialize + push to SignalR
            var evt = DeserializeEvent(args.Message);
            if (evt is ShipmentExcursionDetected e)
                await hub.Clients.Group(e.TenantSlug).SendAsync("ExcursionDetected", e);

            await args.CompleteMessageAsync(args.Message, ct);
        };

        await processor.StartProcessingAsync(ct);
        await Task.Delay(Timeout.Infinite, ct);
    }
}
```

```csharp
// BFF aggregation endpoint — analytical widgets
app.MapGet("/bff/coldchain/dashboard/{tenantSlug}", async (
    string tenantSlug,
    ICellClient cellClient,
    IAssetManagerClient assetManager,
    HybridCache cache,
    CancellationToken ct) =>
{
    // Aggregate from multiple Cells in parallel — cache for 30s
    var cacheKey = $"bff:dashboard:{tenantSlug}";
    return await cache.GetOrCreateAsync(cacheKey, async token =>
    {
        var (shipments, assets) = await (
            coldChain.GetActiveSummaryAsync(tenantSlug, token),
            assetManager.GetAtRiskAssetsAsync(tenantSlug, token)
        ).WhenAll();

        return new DashboardSnapshot(shipments, assets, DateTimeOffset.UtcNow);
    },
    new HybridCacheEntryOptions { Expiration = TimeSpan.FromSeconds(30) }, ct);
})
.RequireAuthorization("SameTenant");
```

```razor
@* Blazor CT component — real-time widget *@
@inject NavigationManager Nav
@inject HubConnection Hub

<div class="glass-card excursion-panel">
    @foreach (var exc in _liveExcursions)
    {
        <ExcursionAlert Excursion="exc" />
    }
</div>

@code {
    private List<ShipmentExcursionDetected> _liveExcursions = [];

    protected override async Task OnInitializedAsync()
    {
        Hub.On<ShipmentExcursionDetected>("ExcursionDetected", exc =>
        {
            _liveExcursions.Insert(0, exc);
            if (_liveExcursions.Count > 10) _liveExcursions.RemoveAt(10);
            InvokeAsync(StateHasChanged);
        });

        await Hub.StartAsync();
    }
}
```

### BFF Rules (C2 must enforce)

```
✅ BFF is read-only — never initiates state changes (no POST/PUT/DELETE to Cell APIs)
✅ All state changes go through Cell APIs directly from Blazor (not via BFF)
✅ BFF caches analytical responses (HybridCache, TTL 30s-5min per widget type)
✅ BFF bypasses cache for real-time widgets (SignalR push, no polling)
✅ BFF is per-tenant aware (Entra ID token flows through, tenant context preserved)
✅ BFF is AOT-compiled (same as Cell APIs)
❌ BFF must never JOIN data from two Cells in a SQL query (no shared DB access)
❌ BFF must never subscribe to Service Bus on behalf of a Cell (Cells own their subscriptions)
❌ BFF must never call a Cell's internal infrastructure (only Cell's public API)
```

### Widget Latency Classification

| Widget | Type | Source | Cache TTL | Real-time? |
|---|---|---|---|---|
| Active excursions | Critical | SignalR push | None | ✅ Yes |
| Live sensor readings | Critical | SignalR push | None | ✅ Yes |
| Oracle risk alerts | Critical | SignalR push | None | ✅ Yes |
| Entity list | Analytical | BFF → Cell API | 30s | ❌ No |
| Asset status grid | Analytical | BFF → AssetManager API | 60s | ❌ No |
| Cost summary | Analytical | BFF → FinTracker API | 5min | ❌ No |
| Compliance report | Analytical | BFF → Cell API | 5min | ❌ No |

---

## Tension 3 Resolution — Sovereign Elite UI Enforcement

### Decision: AHS.Web.Common as Wall + PR Checklist (Small Team)

**Context of this decision:** Team of 2-3 people who know the design system.
The risk is not ignorance — it's fatigue. Someone at 11pm writing glass CSS inline
because it's faster than finding the component. The solution must be frictionless enough
that the right path is also the fast path.

**What this is NOT:** StyleLint CI gates and NetArchTest reading .razor files are
appropriate when AG is the primary code generator (AG has no memory between sessions).
For a small team that knows the system, those layers add CI overhead without proportional
value. They are documented below as an **upgrade path** if AG becomes the primary generator.

### The One Hard Rule: AHS.Web.Common as the Wall

```csharp
// AHS.Web.Common — the canonical component library.
// Rule: if a component exists here, it MUST be used. Never recreated inline.
// New glass/sovereign components go HERE first, then are used in Cells.

// Surfaces
<GlassCard>                     // bg-white/10 backdrop-blur-md border-white/20
<GlassPanel Intensity="Heavy">  // bg-white/[0.18] backdrop-blur-xl
<GlassModal>                    // full modal with backdrop + blur overlay

// Navigation
<SovereignNav>                  // top navigation bar
<CellSideNav>                   // cell-specific side navigation

// Data
<AhsGrid TItem="T">            // QuickGrid + Sovereign Elite styling
<AhsVirtualList TItem="T">     // Virtualize + Sovereign Elite styling

// Forms
<AhsInput>                      // glassmorphism input
<AhsSelect>                     // glassmorphism select
<ReasonForChangeModal>          // universal GxP dialog — mandatory for all commands

// Status
<RiskBand Level="Critical">     // Oracle risk traffic light
<ComplianceStatus>              // GxP compliance indicator
<ExcursionBadge>               // severity badge

// Layout
<CellDashboard>                // standard cell dashboard layout
<CommandConsole>               // full-width operational view
```

```razor
@* ✅ CORRECT — always this pattern *@
<GlassCard>
    <AhsGrid TItem="ShipmentSummaryDto" Items="@_shipments">
        <PropertyColumn Property="@(s => s.Status)" />
    </AhsGrid>
</GlassCard>

@* ❌ WRONG — even if you're in a hurry *@
<div class="bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl p-6">
    <QuickGrid Items="@_shipments">...</QuickGrid>
</div>
@* Consequence: inconsistency accumulates. The next person copies the wrong pattern. *@
```

### PR Checklist (15-second review, lives in .github/pull_request_template.md)

```markdown
## Sovereign Elite — UI checklist
<!-- Takes 15 seconds. Prevents 2 hours of refactor. -->
- [ ] Glass surfaces use `<GlassCard>` / `<GlassPanel>` — not raw Tailwind glass classes
- [ ] Command forms include `<ReasonForChangeModal>` or `ReasonForChange` input
- [ ] Zero hardcoded hex colors — only CSS variables or `hsl(var(--...))` tokens
- [ ] New components added to `AHS.Web.Common`, not defined inline in a Cell
```

```yaml
# .github/pull_request_template.md — commit this to repo root
# No CI overhead. No npm dependencies. No test overhead.
# The team reads it and checks — that's the entire enforcement mechanism.
```

### When to Upgrade to Automated Enforcement

Activate automated enforcement (StyleLint + NetArchTest .razor audit) when ANY of:

```
□ AG becomes the primary code generator for UI components
  → AG has no memory of the rules between sessions — CI must remind it

□ Team grows beyond 3 people
  → New members don't have internalized context — automated gates help onboarding

□ A second violation of the same rule appears in code review within 2 sprints
  → The PR checklist isn't working — escalate to automated enforcement

Activation: the .stylelintrc.json and SovereignEliteEnforcementTests are documented
in the V3.1 archive. Enable them by uncommenting the CI step and registering the test
in the test suite. No design work needed — just flip the switch.
```

---

## Blueprint V3.1.1 — Summary of Changes

| # | Tension | Decision | Codified in |
|---|---|---|---|
| T1 | DB + Multitenancy | Tiered Isolation: RLS now (`IsolationMode.Shared`), Schema upgrade via config flag (`IsolationMode.Isolated`) — zero code change when enterprise tenant arrives | `TenantContext.IsolationMode`, `TenantSessionInterceptor` |
| T2 | CT data aggregation | BFF pattern: SignalR push for critical widgets (<1s), HybridCache 30s-5min for analytical | New project: `AHS.ControlTower.BFF`, `CellEventHub` |
| T3 | Sovereign Elite enforcement | **Small team (2-3):** AHS.Web.Common as wall + PR checklist. No CI linting overhead. Upgrade path to StyleLint + NetArchTest documented for when AG becomes primary generator. | `AHS.Web.Common` component library, `.github/pull_request_template.md` |

**These three decisions are prerequisites for writing any Cell code.**
C2 must include all three in the Prompt Maestro Section 0 of the first Cell.

---

## Pre-Code Verification Checklist

Before C2 writes the first Prompt Maestro for AG, verify:

```
□ T1: TenantContext includes IsolationMode (Shared/Isolated) and SchemaName fields
□ T1: TenantSessionInterceptor handles both modes (set_config vs SET search_path)
□ T1: EF Core migrations have no hardcoded schema names
□ T1: Tenant onboarding script documented (creates schema + runs migrations + updates registry)

□ T2: AHS.ControlTower.BFF project exists in solution structure
□ T2: Widget Classification table agreed (which are real-time vs analytical)
□ T2: SignalR hub defined for critical widgets (ExcursionDetected, OracleAlert)
□ T2: Service Bus "controltower-sub" subscription configured in docker-compose + bicep

□ T3: AHS.Web.Common RCL exists with: GlassCard, GlassPanel, AhsGrid,
       ReasonForChangeModal, SovereignNav, RiskBand
□ T3: .github/pull_request_template.md committed with Sovereign Elite checklist
□ T3: Team agreement — any new glass component goes to AHS.Web.Common first

ALL 11 BOXES CHECKED → Safe to start writing Cell code.
```

---

## Blueprint Supplement V3.1.2 — Naming Framework (2026-03)

### Constitutional Naming Rules (apply to ALL current and future components)

These rules define HOW things are named — not WHAT exists.
The Cell Catalog (`AHS-CELL-CATALOG.md`) records which Cells exist.

#### Namespace Convention

| Component Type | Pattern | Example |
|---|---|---|
| Cell projects | `AHS.Cell.[Name].[Layer]` | `AHS.Cell.[YourCell].Domain` |
| Shell / Hive | `AHS.Web.Hive` | fixed — single organism |
| UI shared library | `AHS.Web.Common` | fixed — design system |
| Foundation | `AHS.Common` | fixed — cross-cutting |
| BFF | `AHS.ControlTower.BFF` | fixed — aggregation layer |

#### Cell Naming Rules
```
1. Cell name must express DOMAIN CAPABILITY, not industry sector
   ❌ "ColdChain" → describes the physical medium
   ✅ "Xinfer"    → describes the capability (Excursion Inference)

2. Cell name must be independently meaningful
   A customer buying ONLY this Cell must understand its value
   from the name alone

3. Cell name must be pronounceable in English, Spanish, and Italian
   (primary markets of AHS ecosystem)

4. Product name (commercial) may differ from technical namespace
   Technical: AHS.Cell.[Name]  →  Commercial: AHS [ProductName]
```

#### Shell Naming
```
AHS Hive — the organism that orchestrates all Cells
  "The hive functions even if individual cells die." (scale-to-zero)
  Biological metaphor is canonical for ALL AHS documentation:
    Hive            = the organism
    Cells           = autonomous organs
    GxP Ledger      = immutable memory
    AOT compilation = exists without JIT dependency
    Sovereign Elite = the exoskeleton
```

#### Rename Protocol (when a Cell is renamed)
```
1. Create PM-RENAME-[OldName]-to-[NewName].md (C2 produces)
2. AG executes rename: namespaces, folders, csproj, slnx, Dockerfile
3. Update AHS-CELL-CATALOG.md (NOT the Blueprint)
4. git commit with message: "refactor: [OldName]→[NewName] per ADR-XXX"
```

> **Note:** The current rename (ColdChain → Xinfer, Web.UI → Hive) is
> documented in `AHS-CELL-CATALOG.md` under Cell history.
> Files: `PM-RENAME-ColdChain-to-Xinfer.md`, `PM-RENAME-WebUI-to-Hive.md`
