# PRD-009: PRD Alignment Strategy

**Status**: Accepted
**Date**: 2026-Q2
**Deciders**: C1 Architect, C2 Lead Engineer
**Scope**: ALL Cells — transversal to entire AHS ecosystem
**Location**: 00_Constitution\ (not in any single Cell)

## Context

As multiple Cells develop their own PRDs, divergence risk exists:
- PRDs referencing outdated ADRs or superseded patterns
- Feature scoping that overlaps between Cells
- Regulatory and metric definitions inconsistent across Cells

## Decision

### 1. Every Cell PRD must reference applicable ADRs

```
ADR-001: Database-per-Cell + Tiered Isolation
ADR-002: Native AOT
ADR-003: Service Bus inter-Cell (no direct HTTP)
ADR-006: SignedCommand universal GxP
ADR-007: Contracts versioning (append-only)
ADR-008: UI Component Boundaries (AHS.Web.Common)
ADR-009: Architectural Alignment (this ADR)
```

### 2. Feature Alignment

```
P0/P1/P2 features must map to Blueprint V3.1.2 roadmap
Out-of-scope features must indicate which Cell covers them
No feature may duplicate a capability of another Cell
```

### 3. Domain Model Consistency

```
Aggregates and roles aligned with global AHS domain model
Inter-Cell relationships documented via events (not shared DB)
ICellEvent contracts documented in Contracts project
```

### 4. Regulatory and Metrics

```
Every PRD must declare:
  - Applicable regulations (FDA, GDPR, HACCP, ISO 27001)
  - GxP operations (which commands require SignedCommand + Ledger)
  - P99 performance targets per endpoint
  - Success metrics (business KPIs)
If metrics depend on another Cell → reference that Cell's PRD
```

### 5. PRD Versioning

```
Cell PRD: versioned with Cell (e.g., Xinfer PRD v1.0, v1.1)
Global PRD summary: maintained in AHS-PRD-AND-TECHNOLOGY-RADAR.md
              aggregate view of all Cell roadmaps
```

## PRD Structure Template (minimum sections)

```markdown
# PRD — AHS.Cell.[Name]
## Version | Status | Blueprint reference

## 1. Problem
## 2. Solution (standalone value proposition)
## 3. Personas (Buyer, User, Regulatory Stakeholder)
## 4. Features (P0 MVP / P1 Growth / P2 Delight / Out of Scope)
## 5. Domain Model (aggregates, events — business language)
## 6. Regulatory Scope (ADR references, GxP operations)
## 7. Integration Map (publishes / consumes)
## 8. Success Metrics (business + technical SLAs)
## 9. ADR References
```

## Consequences

**Positive:**
- Cross-Cell architectural review facilitated
- No duplication or divergence between Cell PRDs
- Automated tooling can validate PRD compliance

**Negative:**
- PRD authors must reference ADRs explicitly (small overhead)
- Global PRD summary requires maintenance when Cells are added
