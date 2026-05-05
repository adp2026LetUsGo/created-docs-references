# AHS Architecture Decision Records
## Blueprint V3.1 — Foundational ADR Set

---

# ADR-001: Database-per-Cell + Multitenancy Strategy

**Status**: Accepted
**Date**: 2025-Q1
**Deciders**: C1 Architect
**Supersedes**: V2.0 shared-schema approach

## Context

AHS V3.1 introduces Cellular Architecture: each Cell must be independently deployable
and sellable as a standalone Micro-SaaS. Simultaneously, AHS is a multitenant SaaS platform.
Two isolation requirements exist simultaneously:
1. Cell isolation (each domain owns its data)
2. Tenant isolation (each customer sees only their data)

## Decision

**Database-per-Cell** is the primary isolation boundary.
**Row-Level Security (RLS)** is the tenant isolation mechanism within each Cell's database.

```
AHS.Cell.ColdChain → PostgreSQL DB: ahs_coldchain (shared by all tenants, RLS-filtered)
AHS.Cell.AssetManager → PostgreSQL DB: ahs_assetmanager (shared by all tenants, RLS-filtered)
AHS.Cell.FinTracker → PostgreSQL DB: ahs_fintracker (shared by all tenants, RLS-filtered)

NOT: 250 databases for 5 cells × 50 tenants
NOT: One shared database with schema-per-cell
YES: One database per Cell, all tenants in that DB, RLS enforces isolation
```

For enterprise tenants requiring physical data isolation (GDPR data residency, contractual):
Schema-per-tenant within the Cell's database is available as an upgrade path (configure per tenant).

## Consequences

**Positive:**
- N databases, not N×M databases (scales with Cell count, not tenant count)
- Cell can be deployed standalone with its own DB (supports standalone commercial model)
- RLS enforced at DB level — application bugs cannot leak cross-tenant data
- Standard Azure Flexible Server serverless tier (autopause) per Cell

**Negative:**
- No cross-Cell JOINs in SQL (mitigated by read model projections via Service Bus)
- Schema migrations per Cell are independent (no shared migration tooling)
- RLS must be configured and tested in every Cell's test suite

**Implementation:**
- `app.current_tenant_id` via PostgreSQL `set_config` (TenantSessionInterceptor)
- `ENABLE ROW LEVEL SECURITY` + `CREATE POLICY` per table in every Cell
- `REVOKE UPDATE, DELETE` on ledger tables (GxP Integrity)
- NetArchTest: verify TenantIsolation tests in every Cell

---

# ADR-002: Native AOT as Default Compilation Target

**Status**: Accepted
**Date**: 2025-Q1
**Deciders**: C1 Architect

## Context

AHS Cells are deployed on Azure Container Apps with `minReplicas: 0` (scale-to-zero).
Cold start latency directly impacts operator experience during incident response —
a quality officer opening the platform during an active excursion cannot wait 3-5 seconds.
Additionally, smaller images reduce Container Registry storage and transfer costs.

## Decision

All AHS Cell APIs and background workers publish as **Native AOT** (PublishAot=true, linux-x64).
Blazor WebAssembly publishes as **WASM AOT** (different from native binary — compiles IL to WASM).
Local tooling, migration scripts, and test projects are **JIT** (no AOT requirement).

**Targets:**
- Cold start: < 50ms (Container Apps scale-from-zero)
- Image size: < 80MB (CI gate enforced)
- Binary: single self-contained executable (no dotnet runtime required in container)

## Consequences

**Positive:**
- Sub-50ms cold starts on scale-to-zero (vs 2-5s with JIT)
- ~35MB images (vs 200MB+ with full runtime)
- Reduced container startup cost (fewer billed cold-start seconds)

**Negative:**
- No reflection: requires JsonSerializerContext, Mapperly, explicit DI registration
- No Assembly.Load(), dynamic, Expression.Compile()
- EF Core: no lazy loading, no runtime model building, explicit query filters
- CI pipeline requires `clang` installation (adds ~30s to build)
- Trim warnings must be treated as errors (IL2026, IL3050) — CI gate

**Implementation:**
- `<PublishAot>true</PublishAot>` in all Cell API .csproj files
- CI step: `dotnet build /p:PublishAot=true /p:EnableTrimAnalyzer=true /warnaserror:IL2026,IL3050`
- CI gate: image size must be < 80MB or pipeline fails
- Template: Dockerfile in `ahs-cell-template` skill

---

# ADR-003: Azure Service Bus as Sole Inter-Cell Channel

**Status**: Accepted
**Date**: 2025-Q1
**Deciders**: C1 Architect

## Context

AHS Cells must maintain autonomy — a Cell must function even if another Cell is unavailable.
Direct HTTP calls between Cells create temporal coupling: if Cell B is down, Cell A fails.
Additionally, multiple Cells may need to react to the same event (fan-out).

## Decision

Inter-Cell communication uses **only** Azure Service Bus topics/subscriptions.
No Cell makes direct HTTP calls to another Cell's API.
The Control Tower (AHS.Web.UI) is the only exception — it aggregates data via HTTP
from Cell APIs for display purposes (it does not initiate state changes via HTTP).

**Pattern:**
- Publisher: uses Outbox Pattern (atomic with DB transaction)
- Topic naming: `ahs.[cellname].events`
- Subscription naming: `[consumercell]-sub`
- Message retention: 7 days (Service Bus standard tier)
- Dead letter queue: monitored via Azure Monitor alert

## Consequences

**Positive:**
- Temporal decoupling — Cell A works even if Cell B is down
- Fan-out: multiple Cells react to one event without publisher knowing
- Replay: dead-letter queue allows reprocessing failed messages
- Audit: Service Bus message history available for debugging

**Negative:**
- Eventual consistency: Cell B's read model may lag behind Cell A's events
- Local dev complexity: requires Service Bus emulator (provided in docker-compose)
- Saga complexity for multi-Cell processes (use sparingly — prefer choreography)
- No request-response pattern (use Control Tower HTTP for queries)

**Exceptions allowed:**
- Control Tower reads Cell APIs via HTTP (display only, no state changes)
- Cells may call external systems (Shopify, Entra ID) via HTTP adapters

---

# ADR-004: PostgreSQL over SQL Server

**Status**: Accepted
**Date**: 2025-Q1
**Deciders**: C1 Architect
**Supersedes**: V2.0 SQL Server assumption

## Context

V2.0 skills were written with SQL Server. V3.1 requires a decision aligned with
Azure cost optimization and open-source stack for Micro-SaaS commercial viability.

## Decision

All AHS Cells use **PostgreSQL 17** via Azure Database for PostgreSQL Flexible Server.
ORM: Npgsql.EntityFrameworkCore.PostgreSQL 10.x + Dapper 2.x.

## Consequences

**Positive:**
- Azure Flexible Server: serverless tier with autopause (zero cost at idle)
- PostgreSQL native types: UUID, JSONB, TIMESTAMPTZ, BIGSERIAL — no NVARCHAR/UNIQUEIDENTIFIER
- Row-Level Security: more elegant than SQL Server's `sp_set_session_context` approach
- JSONB: event payloads are queryable and indexed natively
- Open source: no per-core licensing cost (significant for Micro-SaaS margins)
- `set_config` for tenant context: cleaner than SQL Server SESSION_CONTEXT

**Negative:**
- SQL dialect change: LIMIT vs TOP, snake_case vs PascalCase conventions
- No Azure SQL Managed Instance features (not needed for AHS use case)
- Team must know PostgreSQL-specific features (JSONB operators, COPY for bulk)

**Migration from V2.0 SQL Server:**
- All `NVARCHAR` → `VARCHAR`
- All `UNIQUEIDENTIFIER` → `UUID`
- All `IDENTITY(1,1)` → `BIGSERIAL`
- All `DATETIMEOFFSET` → `TIMESTAMPTZ`
- All `SELECT TOP 1` → `LIMIT 1`
- All `ISNULL()` → `COALESCE()`
- All `sp_set_session_context` → `set_config`

---

# ADR-005: HybridCache as Standard Caching Strategy

**Status**: Accepted
**Date**: 2025-Q1
**Deciders**: C2 Lead Engineer

## Context

AHS Cells have multiple caching needs: device registry lookups (stable, high frequency),
Oracle calculation results (stable per route+conditions, P99 < 10ms requirement),
tenant configuration (stable, loaded once per request), and read model queries (variable TTL).

## Decision

All AHS Cells use **.NET 10 HybridCache** as the unified caching abstraction.
HybridCache provides L1 (IMemoryCache, in-process) + L2 (Redis, distributed) automatically.

**Cache key conventions:**
```
device:{tenantId}:{rawDeviceId}:sensor    TTL: 1h   (device registry)
device:{tenantId}:{rawDeviceId}:zone      TTL: 1h   (device registry)
oracle:{routeId}:{insulation}             TTL: 5m   (Oracle results)
tenant:{tenantSlug}:config                TTL: 55m  (tenant options, refresh before 1h KV cache)
asset:{tenantId}:{assetId}:summary        TTL: 5m   (read model fast path)
```

**What NOT to cache:**
- GxP Ledger entries (never cached — always read from DB for audit integrity)
- SignedCommand results (never cached — each command is unique)
- User authentication state (handled by Entra ID token, not AHS cache)

## Consequences

**Positive:**
- Single cache abstraction: same API for in-process and distributed
- Automatic stampede protection (HybridCache prevents cache thundering herd)
- AOT-safe: no reflection in HybridCache
- Transparent L1 hit: zero network round-trip for hot data

**Negative:**
- Cache invalidation complexity: device registry changes require explicit invalidation
- L1/L2 consistency lag: in-process cache may be stale up to TTL after Redis update
- Redis required in production (local dev uses emulator)

**Implementation:**
```csharp
builder.Services.AddHybridCache();
builder.Services.AddStackExchangeRedisCache(o =>
    o.Configuration = config["Redis:ConnectionString"]);
```

---

# ADR-006: SignedCommand Mandatory for ALL Cells (Universal GxP)

**Status**: Accepted
**Date**: 2025-Q1
**Deciders**: C1 Architect

## Context

V2.0 treated GxP Integrity (SignedCommand + SHA256 Ledger) as a Cold Chain / Pharmaceutical
concern. V3.1 universalizes it. The question is: should ALL Cells require SignedCommand,
or only those with explicit regulatory requirements?

## Decision

**All state-changing commands in ALL AHS Cells inherit SignedCommand.**
ReasonForChange is required in every write operation, regardless of regulatory scope.

Rationale:
1. **Product consistency**: operators learn one interaction model — any change in AHS requires a reason.
2. **Future-proofing**: a Cell that starts as "no regulatory scope" may gain regulatory clients.
   Retrofitting SignedCommand breaks the event history.
3. **Audit culture**: requiring reasons builds organizational discipline in the customer's team.
4. **Competitive differentiation**: "every action in AHS has an explanation" is a product feature.

## Consequences

**Positive:**
- Uniform UX: every modal/form in Sovereign Elite UI has a "Reason for change" field
- Future cells automatically GxP-ready with zero retrofit
- Marketing: "complete audit trail for every action" is a selling point for all Cells

**Negative:**
- UX friction: users must type a reason for every action (mitigated by suggested reasons)
- More verbose commands (extra fields per command)
- Non-regulated customers may find it excessive (position as "enterprise grade by default")

**UX mitigation:**
- Pre-defined reason templates per command type (dropdown + free text)
- "Standard operation" as a valid reason for non-GxP contexts
- Auto-populated from context where deterministic (e.g., "Scheduled maintenance per calendar")

---

# ADR-007: Cell Contracts Versioning Strategy

**Status**: Accepted
**Date**: 2025-Q1
**Deciders**: C2 Lead Engineer

## Context

`AHS.Cell.[Name].Contracts` contains the public events that other Cells consume.
Once published, contracts cannot be changed without potentially breaking consumers.
Need a clear versioning strategy before the first cross-cell integration ships.

## Decision

**Contracts are append-only. Never remove or rename a field.**

Versioning rules:
- **Non-breaking change** (add nullable field): no version suffix, same record type
- **Breaking change** (rename, remove, type change): new record with `_V[N]` suffix
- During transition: publish BOTH old and new versions simultaneously (dual-publish window)
- Deprecation: announce in Cell CHANGELOG, remove old version after 2 sprints

Breaking vs non-breaking classification:
```
Non-breaking (just add):
  + Adding a new nullable field to an existing record
  + Adding a new event type to the Contracts project

Breaking (version bump required):
  - Renaming any field
  - Removing any field
  - Changing a field's type (string → int, etc.)
  - Changing the EventType discriminator string
  - Making a nullable field required
```

## Consequences

**Positive:**
- Consumers never break silently
- Clear migration path with dual-publish window
- JsonSerializer lenient deserialization handles new nullable fields automatically

**Negative:**
- Contracts project grows over time (old versions accumulate)
- Dual-publish window requires temporary code complexity
- Producers must track which consumers have migrated before removing old version

---

# ADR-008: Sovereign Elite UI — Component Boundary

**Status**: Accepted
**Date**: 2025-Q1
**Deciders**: C1 Architect + C2 Lead Engineer

## Context

AHS.Web.Common is the shared Razor Class Library (RCL) for the Sovereign Elite design system.
The question is: which components are shared (in AHS.Web.Common) vs Cell-specific (in Cell's own Blazor module)?

## Decision

**AHS.Web.Common contains:**
- Design tokens (CSS variables: --glass-*, --blur-*, --shadow-glass-*)
- Layout primitives: GlassCard, GlassNav, GlassModal, GlassInput
- Data display: AhsQuickGrid (wrapper around QuickGrid with Sovereign Elite styling)
- Status indicators: ExcursionBadge, RiskBand, ComplianceStatus
- Authentication components: TenantHeader, UserMenu
- Shared utilities: ReasonForChangeModal (universal GxP dialog)
- `CellRegistry` (DI extension for registering cell modules)

**Cell-specific Blazor modules contain:**
- Domain-specific dashboards (ColdChain command console, AssetManager grid)
- Cell-specific forms (shipment creation, asset registration)
- Cell-specific charts (temperature timeline, Oracle XAI DNA panel)
- Any component that uses domain types from that Cell's Domain/Application layer

**Rule:** If a component imports from `AHS.Cell.[X].*`, it belongs in that Cell's Blazor module.
If it's pure UI with no domain dependency, it belongs in AHS.Web.Common.

## Consequences

**Positive:**
- Consistent look across all Cells without code duplication
- New Cell gets Sovereign Elite UI for free by referencing AHS.Web.Common
- ReasonForChangeModal is universal — GxP compliance in all Cells automatically

**Negative:**
- AHS.Web.Common becomes a shared dependency — breaking changes affect all Cells
- Must version AHS.Web.Common carefully (SemVer)
- Shared components must be designed generically (no cold-chain-specific assumptions)

**Versioning:**
- AHS.Web.Common uses SemVer: breaking change = major version bump
- All Cells pin to a specific version, upgrade explicitly
