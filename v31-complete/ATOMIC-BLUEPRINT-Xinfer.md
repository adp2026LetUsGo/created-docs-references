# Atomic Blueprint — AHS.Cell.Xinfer
## Version: 1.1 | Status: Active | Blueprint: V3.1.2
## Produced by: C1 | Input for: C2 + AG
## Last updated: 2026-04-25

---

## 1. IDENTITY

```
Technical Namespace:  AHS.Cell.Xinfer
Product Name:         AHS Xinfer
Tagline:              "Predict. Explain. Prevent."
Naming:               X = Excursion (FDA/GxP — temperature deviation event)
Pronunciation:        "ex-in-fer"
Subdomain Type:       Core Domain
Standalone Product:   Yes — sellable independently as "AHS Xinfer"
Solution Folder:      📁 Cells → Xinfer
Base Path:            src/Cells/Xinfer/
```

### Buyer Personas

| Persona | Role | Pain | Success Metric |
|---|---|---|---|
| Primary Buyer | VP Quality / QA Director | FDA warning letters due to excursions | Zero rejected shipments at inspection |
| Primary User | Cold Chain Operator | Reactive response to excursions | Predict risk before dispatch |
| Regulatory Stakeholder | FDA Inspector / QA Auditor | Black-box AI not auditable | 14-factor XAI DNA per decision |

---

## 2. MISSION

Xinfer predicts excursion risk **before** a shipment departs.
It explains **why** the risk exists (XAI — 14 diagnostic factors).
It recommends **corrective action** before dispatch.
It maintains its **own historical dataset and model lifecycle**.

```
NOT a monitoring system (that would be reactive).
A prediction system (proactive — before the excursion happens).
```

### What makes Xinfer unique
```
1. XAI DNA — 14 factors explain every decision (FDA-auditable)
2. Enforced sequence — prediction cannot run before readiness check
3. Self-governing dataset — selects, validates, and prunes its own data
4. Carrier as modifier — not shipment identity (avoids carrier bias)
5. GxP sealed — every decision immutably recorded with SHA256
```

---

## 3. DOMAIN MODEL

### Aggregates

**ShipmentProfile** — core aggregate
```
Identity:  Product + Route + PackagingType + DepartureDate
           (Carrier is NOT part of identity — it's a risk modifier)

Properties:
  Id:               Guid (private init)
  TenantId:         Guid (private init)
  Identity:         ShipmentIdentity (value object)
  Carrier:          CarrierProfile (value object — modifier only)
  Environmental:    EnvironmentalData (value object)
  Operational:      OperationalData (value object)
  Status:           ShipmentProfileStatus (enum)
  ReadinessState:   abstract record (NotAcceptableState | RiskyState | AcceptableState)
                    NOT a string enum — pattern matching enforced at domain level
  CurrentStep:      XinferStep (enum — enforces sequence)

Factory: ShipmentProfile.Create(identity, carrier, environmental,
                                operational, tenantId, actorId,
                                actorName, reason)

Domain Methods (each raises a DomainEvent):
  ValidateReadiness(result)    → ReadinessValidated
  DetectDivergence(report)     → DivergenceDetected
  SelectHistoricals(dataset)   → HistoricalDatasetSelected
  DecideRetrain(decision)      → RetrainDecisionMade
  RecordPrediction(result)     → PredictionCompleted
  GenerateRecommendations(recs) → RecommendationsGenerated

Invariants:
  - CurrentStep must follow XinferStep enum order (enforced in each method)
  - RecordPrediction() throws XinferSequenceViolationException
    if ReadinessStatus != "Acceptable"
  - Carrier.RiskModifier is applied in prediction, not in identity
```

**ModelVersion** — ML model lifecycle aggregate
```
Properties:
  Id:                   Guid
  TenantId:             Guid
  VersionNumber:        int
  TrainedAt:            DateTimeOffset
  TrainingRecordsCount: int
  AccuracyScore:        double
  IsActive:             bool
  Reason:               string (why this version was trained)

Factory: ModelVersion.Train(dataset, reason, actorId, actorName)
Domain Method: Activate() → ModelActivated event
```

### Value Objects (readonly record struct)

```csharp
ShipmentIdentity(ProductName, ProductCategory, PackagingType, RouteId, DepartureDate)
CarrierProfile(CarrierId, ReliabilityScore, Incidents12M)
  → RiskModifier = 1.0 + (Incidents12M × 0.05) + ((1 - ReliabilityScore) × 0.15)
EnvironmentalData(ForecastMaxCelsius, ForecastMinCelsius, ForecastHumidityPct)
OperationalData(CarrierId, EstimatedDurationHours, DepartureHour)
RiskScore(Value)
  → IsCritical: Value >= 75
  → IsElevated: Value >= 50
XaiDna(Factors[14])  → exactly 14 factors, no more, no less
RetrainDecision(ShouldRetrain, Reason, Severity)
```

### Domain Events (all inherit DomainEvent from AHS.Common)

```
ShipmentProfileCreated(ShipmentProfileId, TenantId, RouteId, PackagingType)
ReadinessValidated(ShipmentProfileId, TenantId, Status, Errors[], Warnings[])
DivergenceDetected(ShipmentProfileId, TenantId, Divergences[])
HistoricalDatasetSelected(ShipmentProfileId, TenantId, RecordCount, Season)
RetrainDecisionMade(ShipmentProfileId, TenantId, ShouldRetrain, Reason, Severity)
ModelRetrained(TenantId, NewVersionNumber, RecordCount, AccuracyScore)
PredictionCompleted(ShipmentProfileId, TenantId, RiskScore, RiskLevel,
                    PessimisticTtfHours, XaiDna)
RecommendationsGenerated(ShipmentProfileId, TenantId, Recommendations[])
```

### Domain Ports (interfaces — Domain layer, zero dependencies)

```
IShipmentInputPort        → ProcessAsync(input, command, ct) → XinferResult
IXinferQueryPort          → GetPredictionAsync, GetReadinessAsync
IHistoricalRepository     → SelectCompatibleAsync, CountAsync, GetKnownRoutesAsync
IModelRepository          → GetActiveAsync, GetByVersionAsync, SaveAsync
IXinferEventPublisher     → PublishAsync(ICellEvent, ct)
IReadinessValidator       → ValidateAsync(input, ct) → ReadinessState
IDivergenceDetector       → DetectAsync(input, ct) → DivergenceReport
IHistoricalSelector       → SelectAsync(input, includeCarrier, ct) → HistoricalDataset
IRetrainDecider           → EvaluateAsync(dataset, divergence, ct) → RetrainDecision
IPredictionEngine         → PredictAsync(input, dataset, model, ct) → PredictionResult
IRecommender              → Generate(prediction, input, dataset) → Recommendations[]
```

### Application Ports (introduced by AG — hexagonal purity)

```
IXinferDbContext          → Port breaking circular dependency between Application
                            and Infrastructure layers.
                            Application depends on this — NOT on XinferDbContext directly.
                            Location: AHS.Cell.Xinfer.Application/Ports/IXinferDbContext.cs
                            Implemented by: XinferDbContext (Infrastructure)

IOutboxWriter             → WriteAsync(tenantId, eventType, payloadJson, ct)
                            Atomic write to outbox_messages within handler transaction.
                            Location: AHS.Cell.Xinfer.Application/Ports/IOutboxWriter.cs
                            Implemented by: OutboxWriter (Infrastructure)
```

---

## 4. EXECUTION SEQUENCE (mandatory — domain invariant)

```
XinferStep enum order (CurrentStep must always advance forward):

  Step 1: DataInterpretation    → ShipmentProfile.Create()
  Step 2: ReadinessValidation   → ValidateReadiness()
  Step 3: DivergenceDetection   → DetectDivergence()
  Step 4: HistoricalSelection   → SelectHistoricals()
  Step 5: RetrainDecision       → DecideRetrain()
  Step 6: Retraining            → (async, only if ShouldRetrain = true)
  Step 7: Prediction            → RecordPrediction()
  Step 8: Recommendations       → GenerateRecommendations()

CRITICAL INVARIANT:
  RecordPrediction() MUST throw XinferSequenceViolationException if:
    - CurrentStep < Step 5 (ReadinessValidation not complete)
    - ReadinessStatus == "NotAcceptable"

  This is enforced at DOMAIN level, not application level.
  AG must generate this check INSIDE the domain method, not in the handler.
```

---

## 5. REGULATORY SCOPE

| Regulation | Applies | Key Requirement |
|---|---|---|
| FDA 21 CFR Part 11 | ✅ Mandatory | SignedCommand + SHA256 Ledger on all writes |
| EU GMP Annex 11 | ✅ Mandatory | ALCOA+ compliance, export capability |
| HACCP | ✅ For food/pharma cargo | CCP validation in ReadinessValidator |
| GDPR | ✅ EU customers | PII separated from events, carrier ID not PII |
| ISO 27001 | ✅ All Cells | Key Vault + structured logging |

### GxP Operations (require SignedCommand + Ledger entry)
```
- Submit shipment for evaluation
- Trigger manual retraining
- Apply What-If parameter change
- Override readiness decision (Quality Officer only)
```

### XAI Regulatory Requirement
```
Every PredictionResult MUST include XaiDna with exactly 14 factors.
Reason: FDA auditors require explanation of AI decisions.
A black-box risk score fails 21 CFR Part 11 audit.
The 14 factors are the "audit trail of the algorithm".
```

---

## 6. INTEGRATION MAP

### Events Xinfer publishes (Service Bus topic: ahs.xinfer.events)

| Event | Trigger | Consumers |
|---|---|---|
| ReadinessOkEvent | Readiness = Acceptable | AHS Hive (dashboard update) |
| ReadinessFailEvent | Readiness = NotAcceptable | AHS Hive (alert) |
| RetrainRequiredEvent | RetrainDecision.ShouldRetrain = true | AHS Hive (notification) |
| PredictOkEvent | Prediction completed | AssetManager (mark at risk), FinTracker (insurance trigger), AHS Hive (dashboard) |

### Events Xinfer consumes
```
None currently. Xinfer is the data producer, not consumer.
Future: may consume AssetManager.MaintenanceCompleted to update carrier scoring.
```

### External systems (via Adapter/Port)
```
Input adapters (ISensorAdapter / IShipmentInputPort):
  Local    → CSV/Excel from wwwroot/data/ (demo mode)
  Azure    → Azure Blob Storage / Event Hub
  OCI      → Oracle Cloud Infrastructure Object Storage
  Firebase → Firebase Realtime Database

Selection: config["Xinfer:InputAdapter"] → switch expression (AOT-safe)
```

---

## 7. DATA SCHEMA

### Tables

```sql
shipment_profiles       → aggregate state (EF Core writes, Dapper reads)
historical_records      → training data (Xinfer owns this — no other Cell touches it)
model_versions          → ML model lifecycle
ledger_entries          → GxP Ledger (inherited from AHS.Common pattern)
outbox_messages         → Outbox Pattern (guaranteed Service Bus delivery)
                          ✅ Implemented by AG (PM-FIX-Xinfer-Outbox-Health)
                          BackgroundService: OutboxPublisherService
                          Retry: max 5 attempts, SKIP LOCKED
```

### Key indexes
```sql
ix_historical_route_pkg_season  ON historical_records(tenant_id, route_id, packaging_type, season)
ix_model_active                 ON model_versions(tenant_id, is_active) WHERE is_active = true
ix_outbox_unpublished           ON outbox_messages(created_at) WHERE published_at IS NULL
```

### RLS Policy (all tables)
```sql
CREATE POLICY xinfer_tenant_isolation ON [table]
    USING (tenant_id = current_setting('app.current_tenant_id')::uuid);
REVOKE UPDATE, DELETE ON ledger_entries FROM app_role;
```

---

## 8. TECHNICAL CONSTRAINTS

### Implemented infrastructure (post-fix — AG delivered)
```
✅ Outbox Pattern:        outbox_messages table + OutboxPublisherService
                          Atomic: prediction + outbox in one DB transaction
                          PublishAsync removed from Application layer
                          
✅ Operational Health:    GET /health/operational → XinferHealthDto
                          XinferLifecycleState: Initializing|Ready|Retraining|Degraded|Draining|Maintenance
                          OutboxPending count, ModelVersion, IsRetraining

✅ IXinferDbContext port: Hexagonal purity — Application → port → Infrastructure
                          Resolves AOT circular dependency issue

✅ Contracts created:     PredictOkEvent, ReadinessFailEvent, RetrainRequiredEvent
                          All in AHS.Cell.Xinfer.Contracts
                          Registered in XinferContractsJsonContext
```

### Performance targets
```
Prediction P99:          < 5ms  (PredictionEngine hot path)
API response P99:        < 200ms (full 8-step sequence, cached model)
Sensor/input ingestion:  < 50ms
Cold start (AOT):        < 50ms (Azure Container Apps scale-to-zero)
Docker image size:       < 80MB
```

### AOT rules specific to Xinfer
```
PredictionEngine:
  - 14 factors computed via Span<double> stackalloc — no heap
  - No LINQ in Calculate() method
  - RiskScore uses Generic Math operators (C# 14)

HistoricalSelector:
  - IQR outlier removal via direct array sort — no LINQ
  - stackalloc for ≤256 records, heap fallback for larger datasets

All serialization:
  - XinferJsonContext covers all API boundary types
  - XinferContractsJsonContext covers all ICellEvent types
```

### Carrier rule (critical for correct implementation)
```
Carrier = risk modifier, NOT shipment identity.

ShipmentIdentity = Product + Route + PackagingType + DepartureDate
CarrierProfile   = modifier applied during PredictionEngine scoring

Implication:
  Two identical shipments with different carriers
  → Same ShipmentIdentity (same Id)
  → Different RiskScore (carrier modifier differs)

AG must implement this as two separate value objects,
NOT as part of the aggregate identity.
```

---

## 9. UI SPECIFICATION

### Existing components (DO NOT regenerate)
```
AlphaBox.razor       → Doom Clock (TTF countdown) — reacts to PredictionResult.PessimisticTtfHours
XaiRiskMonitor.razor → Risk % widget — reacts to PredictionResult.RiskScore
XaiDiagnostic.razor  → XAI DNA panel — shows all 14 factors
WhatIfSimulator.razor → Input form — produces ShipmentInputDto
AuditLedger.razor    → GxP entries — shows sealed ledger events
TelemetryHud.razor   → Footer HUD — shows PredictionEngine latency
DeltaTChart.razor    → Thermal projection chart
```

### Dashboard page
```
Route:   /xinfer/dashboard
Layout:  AhsCommandLayout (sidebar + topbar + TelemetryHud footer)
Data:    ICsvXinferService (CSV) → replace with IXinferQueryPort when API ready

Bento Grid (4 columns):
  Row 1: AlphaBox | Fleet KPI | Oracle Risk | DataBridge
  Row 2: ORACLE_RISK_LENS_PRO table (3 cols) | WhatIfSimulator + XaiRiskMonitor (1 col)
  Row 3: AuditLedger (4 cols, full width)
```

### What-If → Prediction flow (UI)
```
1. Operator fills WhatIfSimulator form
2. OnAnalyze callback → HandleWhatIfAnalysis()
3. Handler calls API → POST /api/xinfer/evaluate
4. Response updates: XaiRiskMonitor (risk %), AlphaBox (TTF),
                     AuditLedger (new GxP entry), TelemetryHud (latency)
5. If RiskScore >= 75: AlphaBox pulses red (neon-throb animation)
```

---

## 10. QUALITY GATES

### Critical tests (must pass — non-negotiable)
```
□ PredictionEngine returns exactly 14 XAI DNA factors
□ PassiveChamber adds exactly 15% penalty to base score
□ XinferSequenceViolationException thrown if Prediction called before Readiness
□ RetrainDecider returns ShouldRetrain=true for all 6 criteria independently
□ HistoricalSelector throws InsufficientHistoricalDataException if < 5 records
□ Carrier treated as modifier — same shipment, diff carrier = same ShipmentIdentity
□ TenantA cannot see TenantB shipment profiles (RLS enforcement)
□ SignedCommand rejects empty ReasonForChange
```

### BDD scenarios (@tags)
```
@REQ-001 @GxP:   PassiveChamber 15% penalty
@REQ-001 @GxP:   XAI DNA 14 factors present
@GxP @21CFR11:   What-If change sealed in Ledger with SHA256
@GxP:            ReadinessFailure blocks prediction
@GxP:            Sequence violation throws exception
```

### CI gates
```
grep -r "Activator" src/Cells/Xinfer → 0 results
grep -r "\.Where\|\.Select\|\.Sum" src/Cells/Xinfer/.../PredictionEngine.cs → 0 results
dotnet publish /p:PublishAot=true → 0 trim warnings
docker build → image < 80MB
```

---
*Atomic Blueprint — AHS.Cell.Xinfer v1.0*
*Single source of truth for Xinfer Cell design decisions*
*Update this document when domain rules change — not the Blueprint V3.1.2*
*Cell-level changes: update AHS-CELL-CATALOG.md status*