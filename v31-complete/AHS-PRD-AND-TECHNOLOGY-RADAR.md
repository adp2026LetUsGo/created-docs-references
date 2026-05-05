# AHS Product Requirements — Cell PRD Set
## Blueprint V3.1 / C1 Architect Output

---

# MASTER PRODUCT ROADMAP

## AHS Ecosystem — Release Plan

| Phase | Cells | Quarter | Goal |
|---|---|---|---|
| **Phase 1 — Foundation** | ColdChain (refactor V2→V3.1) | Q2 2025 | First V3.1 Cell in production |
| **Phase 2 — Expansion** | AssetManager (new) | Q3 2025 | First new Cell using V3.1 template |
| **Phase 3 — Revenue** | FinTracker (new) | Q4 2025 | First Cell sold standalone |
| **Phase 4 — Ecosystem** | ShopifyBridge (new) + Control Tower integration | Q1 2026 | Full multi-cell orchestration |
| **Phase 5 — Platform** | [Customer-requested Cells] | 2026+ | AHS as a Cell factory |

---

# PRD-001: AHS ColdChain Cell
## "The Active Defense System for Pharmaceutical Cold Chain"

**Version**: 3.0 (V3.1 refactor of V2.0)
**Status**: In Development
**Cell namespace**: AHS.Cell.ColdChain
**Subdomain**: Core Domain
**Standalone product name**: AHS ColdGuard

---

### 1. The Problem

Pharmaceutical companies lose between €50K and €2M per excursion event when they
cannot prove regulatory compliance. Current solutions (paper logs, basic data loggers,
legacy LIMS) fail at three points:
- Cannot provide real-time predictive risk (they react, not predict)
- Cannot generate GxP-compliant audit trails automatically (manual, error-prone)
- Cannot explain WHY a risk decision was made (black-box algorithms fail FDA audits)

### 2. Solution — Standalone Value Proposition

AHS ColdGuard is the only cold chain platform that provides:
1. **Active prediction**: Logistics Oracle (REQ-001) calculates Pessimistic TTF before excursion occurs
2. **Explainable AI**: 14-point XAI DNA for every risk decision (audit-ready, FDA-approved)
3. **Immutable compliance**: SHA256-sealed GxP Ledger — tamper-evident by design

Tagline: *"From passive logging to active defense."*

### 3. Target Personas

**Primary Buyer**: VP Quality / QA Director (pharmaceutical logistics)
- Pain: FDA warning letters due to inadequate electronic records
- Budget: €20-80K/year for compliance tools
- Decision trigger: regulatory audit failure or near-miss

**Primary User**: Cold Chain Operator
- Daily workflow: monitor dashboard, respond to alerts, document decisions
- Success: zero unresolved excursions, all records audit-ready

**Regulatory Stakeholder**: FDA Inspector / QA Auditor
- Need: complete, tamper-evident records exported on demand
- Format: PDF + CSV export with hash verification

### 4. Features

#### P0 — MVP
| ID | Feature | User Story | Acceptance Criteria |
|---|---|---|---|
| F-001 | Shipment lifecycle | As an operator, I want to create and track pharmaceutical shipments | Create, monitor, seal shipment with full GxP audit trail |
| F-002 | Excursion detection | As an operator, I want immediate alerts when temperature leaves setpoint | Alert fires within 1 alarm delay cycle; severity classified |
| F-003 | Logistics Oracle | As a QA director, I want risk assessment before dispatch | Oracle returns result in P99 < 10ms; XAI DNA has 14 factors |
| F-004 | GxP Ledger | As a QA auditor, I want tamper-evident records | SHA256 chain verifiable; export PDF/CSV with hash |
| F-005 | What-If Simulator | As an operator, I want to model route changes | Every parameter change requires ReasonForChange; sealed in Ledger |
| F-006 | MKT Report | As a QA director, I want Mean Kinetic Temperature at shipment close | MKT calculated per ICH Q1A; included in sealed report |
| F-007 | Multi-protocol ingestion | As a customer, I want to use my existing sensors | HTTP webhook + at least 1 other protocol; Device Registry for mapping |
| F-008 | Tenant management | As a tenant admin, I want to configure zones and setpoints | Per-tenant zone profiles; setpoint validation |

#### P1 — Growth
| ID | Feature | Rationale |
|---|---|---|
| F-101 | Stability Budget calculator | Key differentiator for pharma — cumulative excursion budget per product |
| F-102 | Route risk library | Pre-configured Oracle risk profiles for 50+ common routes |
| F-103 | Carrier scorecard | Track carrier reliability over time; feed into Oracle |
| F-104 | Regulatory export templates | Pre-formatted exports per agency (FDA, EMA, COFEPRIS) |
| F-105 | API for LIMS integration | Customers want ColdGuard to push data to their existing LIMS |

#### P2 — Delight
| ID | Feature | Rationale |
|---|---|---|
| F-201 | Predictive maintenance alerts | Correlate excursions with carrier incidents to predict future risk |
| F-202 | Benchmarking dashboard | Compare carrier performance across tenant's shipment history |
| F-203 | Mobile-first incident response | Operator app for field resolution of excursions |

#### Out of Scope
- Asset management of refrigeration equipment → AssetManager Cell
- Financial cost tracking of shipments → FinTracker Cell
- Carrier payments → Generic subdomain (Stripe)

### 5. Domain Model

| Aggregate | Business Role | Key Invariants |
|---|---|---|
| Shipment | A cargo movement from A to B under temperature control | Cannot be sealed without all CCPs resolved; MKT within limits |
| TemperatureZone | A controlled environment with setpoints | MinCelsius < MaxCelsius; AlarmDelay > 0 |
| Sensor | A registered monitoring device | One Sensor → one Zone; must be in Device Registry |

### 6. Regulatory Scope

| Regulation | Status | Key Requirement |
|---|---|---|
| FDA 21 CFR Part 11 | Mandatory | SignedCommand + SHA256 Ledger on all write operations |
| EU GMP Annex 11 | Mandatory | ALCOA+ compliance, export capability |
| HACCP | Mandatory for food cargo | CCP configuration, corrective action workflow |
| GDPR | Conditional | PII separated from event payloads; data residency per tenant |

### 7. Success Metrics

| Metric | Target |
|---|---|
| Oracle P99 latency | < 10ms |
| Sensor ingestion P99 | < 50ms |
| FDA audit export generation | < 5s |
| System availability | 99.9% |
| Excursion false positive rate | < 2% |

---

# PRD-002: AHS AssetManager Cell
## "GxP-Grade Asset Intelligence for Industrial Operations"

**Version**: 1.0 (new Cell)
**Status**: Planned — Q3 2025
**Cell namespace**: AHS.Cell.AssetManager
**Subdomain**: Supporting Domain
**Standalone product name**: AHS AssetTrack

---

### 1. The Problem

Industrial operations (pharma, food, chemical) track GMP-critical equipment in
spreadsheets or disconnected CMMS systems. When an FDA inspector asks "who approved
the last calibration of refrigerator unit R-042?", the answer takes hours to produce
— if it can be produced at all. Equipment with lapsed calibration causes batch rejection.

### 2. Solution — Standalone Value Proposition

AHS AssetTrack provides GxP-grade asset lifecycle management: register, maintain,
calibrate, and retire equipment with a complete, tamper-evident audit trail.
Every action is signed, sealed, and exportable for regulatory inspection.

Tagline: *"Every asset. Every action. Every answer."*

### 3. Target Personas

**Primary Buyer**: Maintenance Manager / Operations Director
- Pain: failed audits due to missing maintenance records
- Current solution: Excel + sticky notes + tribal knowledge

**Primary User**: Maintenance Technician / QA Coordinator
- Daily workflow: log maintenance, schedule calibration, respond to alerts

### 4. Features

#### P0 — MVP
| ID | Feature | User Story | Acceptance Criteria |
|---|---|---|---|
| F-001 | Asset register | Register equipment with category, serial number, location | Full audit trail; serial number validated |
| F-002 | Maintenance scheduling | Schedule and record maintenance events | SignedCommand required; Ledger sealed |
| F-003 | Calibration tracking | Track calibration due dates, record results | Alert when calibration due in < 30 days |
| F-004 | Asset retirement | Retire or scrap equipment with full audit | ReasonForChange mandatory; Ledger sealed |
| F-005 | GxP audit export | Export complete asset history for inspection | PDF + CSV; hash-verifiable |
| F-006 | Cold Chain integration | Mark asset at-risk when ColdChain excursion detected | Reacts to ShipmentExcursionDetected event |

#### Out of Scope
- Financial depreciation → FinTracker Cell
- Temperature monitoring → ColdChain Cell
- Procurement → Generic subdomain (ERP integration)

### 5. Domain Model

| Aggregate | Business Role | Key Invariants |
|---|---|---|
| Asset | Physical equipment in the operation | SerialNumber unique per tenant; cannot retire active asset without documentation |
| MaintenanceRecord | A completed maintenance event | Signed by qualified technician; linked to Asset |

### 6. Regulatory Scope
- ISO 55001: Asset management lifecycle
- FDA 21 CFR Part 11: For GMP-critical assets (calibrated equipment, controlled environments)
- GDPR: Technician names in records → pseudonymization option

---

# PRD-003: AHS FinTracker Cell
## "Multi-Currency Cost Intelligence for Logistics Operations"

**Version**: 1.0 (new Cell)
**Status**: Planned — Q4 2025
**Cell namespace**: AHS.Cell.FinTracker
**Subdomain**: Supporting Domain
**Standalone product name**: AHS FinLens

---

### 1. The Problem

Logistics companies operate across multiple currencies, billing structures, and cost
centers. Allocating costs to shipments (fuel, cold storage, carrier fees, excursion
losses) requires data from multiple systems that don't talk to each other.
CFOs cannot answer "what did Shipment S-2024-004 cost us end-to-end?" in real time.

### 2. Solution — Standalone Value Proposition

AHS FinLens tracks all costs associated with logistics operations, allocates them
to shipments, converts to reporting currency in real time, and produces CFO-ready reports.

Tagline: *"Every cost. Every currency. Every shipment."*

### 3. Target Personas

**Primary Buyer**: CFO / Finance Director (logistics or pharma)
- Pain: month-end cost reconciliation takes 5 days; shipment profitability unknown
- Current solution: Excel pivot tables

**Primary User**: Finance Analyst / Operations Controller
- Daily workflow: enter costs, allocate to shipments, run reports

### 4. Features

#### P0 — MVP
| ID | Feature | User Story | Acceptance Criteria |
|---|---|---|---|
| F-001 | Cost entry | Record operational costs with category and currency | Multi-currency input; auto-convert to base currency |
| F-002 | Shipment allocation | Allocate costs to specific shipments | Integration with ColdChain Cell via ShipmentId |
| F-003 | Excursion cost tracking | Automatically log cost when ColdChain excursion resolved | Reacts to ExcursionResolved event; prompts cost entry |
| F-004 | Multi-currency reporting | Report in any supported currency | ECB exchange rate integration; daily rate refresh |
| F-005 | Cost audit trail | SignedCommand + Ledger for all cost adjustments | ReasonForChange mandatory for any cost modification |

#### Out of Scope
- Payment initiation (PSD2) → Generic subdomain (Stripe / bank API)
- Invoicing → Generic subdomain (accounting software integration)
- Payroll → Not in AHS scope

### 5. Regulatory Scope
- GDPR: Payment reference data → pseudonymization
- GDPR: Data residency for EU financial data
- SOX: If customer is publicly traded (audit trail covers this)
- PCI DSS: Only if card data is stored (recommendation: never store — tokenize)

---

# TECHNOLOGY RADAR — AHS Ecosystem V3.1

## Adopt (use by default — no discussion needed)

| Technology | Category | Rationale |
|---|---|---|
| C# 14 / .NET 10 LTS | Runtime | Stable LTS, AOT support, C# 14 features in production |
| Native AOT (linux-x64) | Compilation | Sub-50ms cold starts, < 80MB images |
| PostgreSQL 17 | Database | UUID/JSONB native, RLS, serverless tier on Azure |
| Npgsql 9.x | ORM driver | Native .NET PostgreSQL driver, AOT-safe |
| EF Core 10 (Source Gen) | Write ORM | Write-side persistence, AOT-safe with source gen |
| Dapper 2.x | Read ORM | Zero-overhead queries, pure SQL, AOT-safe |
| HybridCache (.NET 10) | Caching | L1+L2 unified, AOT-safe, stampede protection |
| Redis 7 (StackExchange) | Cache L2 | Industry standard, Azure Cache for Redis available |
| Azure Service Bus | Messaging | Managed, AMQP, dead-letter, Service Bus Emulator for dev |
| Azure Container Apps | Deployment | Scale-to-zero, managed, Bicep support |
| Azure Key Vault | Secrets | Managed Identity, HSM-backed, 90-day soft-delete |
| Microsoft Entra ID | Identity | OIDC, custom claims, managed identity |
| Blazor (.NET 10, Auto) | UI | AOT WASM + Server, PersistentState, ValidatableType |
| Tailwind CSS 4 | Styling | Utility-first, Sovereign Elite glassmorphism |
| xUnit 2.x | Testing | Standard .NET test framework |
| FluentAssertions 7 | Assertions | Readable, domain-specific assertion extensions |
| NSubstitute 5 | Mocking | AOT-safe (no Castle DynamicProxy) |
| Testcontainers 3 | Integration test | Real PostgreSQL + Redis in tests |
| NetArchTest.eNet | Architecture | Blueprint guardrail enforcement |
| Reqnroll 2 | BDD | .NET successor to SpecFlow, Gherkin |
| GitHub Actions | CI/CD | Free tier, OIDC Azure auth, AOT build support |
| Azure Bicep | IaC | Typed ARM, Cell modules pattern |
| Mapperly | Object mapping | Source-gen mapper, AOT-safe AutoMapper replacement |

## Trial (evaluate — use in non-critical Cells first)

| Technology | Category | Reason for trial |
|---|---|---|
| Aspire (.NET 10) | Local orchestration | Simplifies local multi-Cell dev (replaces docker-compose) — mature in .NET 10 |
| OpenTelemetry .NET | Observability | Cross-Cell trace correlation — evaluate overhead on AOT |
| Azure Managed Grafana | Monitoring | Replace Azure Monitor dashboards for cold chain telemetry |
| Scalar | API docs | Modern OpenAPI UI (replaces Swagger UI for AOT Minimal APIs) |
| Wolverine | Messaging | CQRS + Service Bus + Outbox in one library — evaluate AOT compatibility |

## Hold (do not start new projects with these)

| Technology | Category | Reason |
|---|---|---|
| MediatR | CQRS mediator | Reflection-based — incompatible with Native AOT |
| AutoMapper | Object mapping | Reflection-based — use Mapperly instead |
| Castle Windsor / DynamicProxy | DI / mocking | Reflection + Emit — incompatible with Native AOT |
| SQL Server | Database | Replaced by PostgreSQL (see ADR-004) |
| Entity Framework Core lazy loading | ORM feature | Incompatible with Native AOT |
| DataContractSerializer / XmlSerializer | Serialization | Use System.Text.Json + JsonSerializerContext |
| BinaryFormatter | Serialization | Deprecated, security risk |
| Hangfire | Background jobs | Reflection-based scheduler — use BackgroundService + Service Bus |
| NLog / log4net | Logging | Use Microsoft.Extensions.Logging + OpenTelemetry |

## Avoid (do not use — violates Blueprint guardrails)

| Technology | Category | Why forbidden |
|---|---|---|
| Any reflection-based DI (without source gen) | DI | Breaks Native AOT (G1) |
| SharedDB between Cells | Architecture | Violates Database-per-Cell (ADR-001) |
| Direct HTTP between Cells | Integration | Violates Service Bus rule (ADR-003) |
| Hardcoded hex colors in Blazor | UI | Violates Sovereign Elite (G5) |
| Inter / Roboto fonts with purple gradient | UI | "AI slop" aesthetic — explicitly rejected |
| LINQ in hot paths (Oracle, HPC) | Performance | Heap allocations — use Span<T>, direct loops |
| Assembly.Load() / Activator.CreateInstance | Reflection | Breaks Native AOT (G1) |
| string.Format / $"..." in hot paths | Performance | Heap allocations — use Span<char> / stackalloc |
