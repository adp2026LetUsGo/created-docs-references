# ADR-009: Architectural Alignment Strategy

**Status**: Accepted
**Date**: 2026-Q2
**Deciders**: C1 Architect, C2 Lead Engineer
**Scope**: ALL Cells — transversal to entire AHS ecosystem
**Location**: 00_Constitution\ (not in any single Cell)

## Context

Blueprint V3.1.2 defines the constitutional rules. However, as the number
of Cells grows, divergence risk increases without explicit enforcement:

- Cells implementing different DI, caching, or messaging patterns
- UI components duplicated across Cells instead of using AHS.Web.Common
- Contract versioning inconsistencies breaking consumers
- Operational drift in logging, CI/CD pipelines, and monitoring

## Decision

### 1. Cross-Cell Standards (enforced in CI)

Every Cell MUST implement:
```
✅ Native AOT compilation (PublishAot=true in Release)
✅ HybridCache configuration (ADR-005)
✅ SignedCommand on ALL write operations (ADR-006)
✅ TenantSessionInterceptor via AHS.Common (ADR-001)
✅ JsonSerializerContext for all API boundary types (ADR-002)
✅ Static Rehydrate() factory on all aggregates (AOT rule)
```

CI validation job: `.github/workflows/validate-adr-alignment.yml`
Checks: AOT trim warnings, Activator.CreateInstance grep, SignedCommand inheritance

### 2. Contracts Governance (ADR-007 strict enforcement)

```
Breaking change  → new record type with _V[N] suffix
Non-breaking     → add nullable field to existing record
Dual-publish     → 2 sprints minimum before removing old version
CI job           → validates all published events conform to versioning rules
```

### 3. UI Alignment (ADR-008 enforcement)

```
All Cells consume AHS.Web.Common components — never raw glass CSS
Cell-specific components ONLY if they import domain types from that Cell
AHS.Web.Common uses SemVer — breaking change = major version bump
PR template includes Sovereign Elite checklist (4 items, 15 seconds)
```

### 4. Operational Alignment

```
Logging:    Structured + AnalysisId/TenantId correlation in every log entry
Metrics:    Azure Monitor standard keys per Cell
Containers: Image size < 80MB, tag format: {cell}-{version}-{commit}
CI/CD:      Standard pipeline stages: build → test → aot-trim → docker → deploy
```

### 5. Periodic Architectural Review

```
Quarterly: review all Cells for compliance with ADR standards
           detect drift, duplication, documentation gaps
           update AHS-CELL-CATALOG.md status fields
```

## Consequences

**Positive:**
- Minimized divergence across Cells
- Faster Cell onboarding (reusable patterns + templates)
- Consistent UX and GxP compliance

**Negative:**
- Additional CI/CD complexity for validation jobs
- Shared UI creates coupling (managed via SemVer)

## Implementation Checklist (per new Cell)

```
□ PublishAot=true in Release csproj
□ TenantSessionInterceptor registered in DI
□ SignedCommand inherited by all write commands
□ JsonSerializerContext covers all API types
□ No Activator.CreateInstance anywhere
□ AHS.Web.Common referenced (not raw glass CSS)
□ CI pipeline includes aot-trim gate
□ PR template with Sovereign Elite checklist committed
□ Cell registered in AHS-CELL-CATALOG.md
```
