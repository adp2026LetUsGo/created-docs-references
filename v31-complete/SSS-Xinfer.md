# System Sequence Specifications — AHS.Cell.Xinfer
## Version: 1.0 | Blueprint: V3.1.2 | Produced by: C1
## Input for: C2 (handler design) + AG (implementation)

---

# SSS-001: Shipment Risk Evaluation (Primary Flow)

## Use Case
**Actor:** Logistics Operator / QA Analyst
**Goal:** Evaluate excursion risk for a shipment before dispatch
**Precondition:** AHS Hive dashboard open, at least 5 historical records in DB

## Happy Path

```
ACTOR                    UI (Blazor)              API                      DOMAIN                   INFRA
─────                    ───────────              ───                      ──────                   ─────
Fill WhatIfSimulator     
  [CarrierProtocol]      
  [InsulationType]       
  [ExternalForecast]     
Click INYECTAR_SIMULACIÓN
                    ──→  HandleWhatIfAnalysis()
                         Validate form fields
                         Show loading state
                    ──→  POST /api/xinfer/evaluate
                         {ShipmentInputDto,
                          ReasonForChange,
                          SignedById}
                                          ──→  SubmitShipmentHandler
                                               Validate SignedCommand
                                               (empty reason → 400)
                                               
                                          ──→  Step 1: Create ShipmentProfile
                                               ShipmentProfile.Create(
                                                 identity, carrier,
                                                 environmental, operational)
                                               → ShipmentProfileCreated event
                                               → Append to GxP Ledger
                                               
                                          ──→  Step 2: ReadinessValidator
                                               9 checks executed
                                               → ReadinessResult{Status, Errors[], Warnings[]}
                                               → ReadinessValidated event → Ledger
                                               
                                               IF Status = NotAcceptable:
                                                 → ReadinessFailEvent → Service Bus
                                                 → Return 422 {errors, warnings}
                                               
                                          ──→  Step 3: DivergenceDetector
                                               Route, carrier, packaging, season checks
                                               → DivergenceReport{HasDivergence, Divergences[]}
                                               → DivergenceDetected event → Ledger
                                               
                                          ──→  Step 4: HistoricalSelector
                                               SELECT compatible records
                                               (route + packaging + season + optional carrier)
                                               Remove outliers (IQR)
                                               IF count < 5 → InsufficientHistoricalDataException
                                               → HistoricalDataset{Records, Season, RecordCount}
                                               → HistoricalDatasetSelected → Ledger
                                               
                                          ──→  Step 5: RetrainDecider
                                               Evaluate 6 criteria
                                               → RetrainDecision{ShouldRetrain, Reason, Severity}
                                               → RetrainDecisionMade → Ledger
                                               
                                               IF ShouldRetrain = true:
                                                 → RetrainRequiredEvent → Service Bus (async)
                                                 → Retraining queued (BackgroundService)
                                                 → Continue with current active model
                                               
                                          ──→  Step 6 (async, non-blocking):
                                               IF queued: ModelTrainer runs in background
                                               Current prediction uses existing active model
                                               
                                          ──→  Step 7: PredictionEngine
                                               Load active ModelVersion
                                               Calculate 14 XAI DNA factors (Span<double>)
                                               Apply passive penalty if PackagingType=PassiveChamber
                                               Calculate PessimisticTTF + SafeWindow
                                               → PredictionResult{RiskScore, XaiDna, TTF}
                                               → PredictionCompleted → Ledger (SHA256 sealed)
                                               
                                          ──→  Step 8: Recommender
                                               Apply rule-based recommendations
                                               → Recommendations[]
                                               → RecommendationsGenerated → Ledger
                                               
                                          ──→  Outbox: PredictOkEvent → Service Bus
                                               (atomic with DB transaction)
                                               
                                    ←──  XinferResult{
                                           Readiness, Divergence,
                                           RetrainDecision,
                                           Prediction, Recommendations
                                         }
                    ←──  200 OK PredictionResultDto
                         {RiskScore, RiskLevel,
                          PessimisticTtfHours,
                          XaiDna[14], Recommendations}
                         
Update UI components:
  XaiRiskMonitor → RiskScore %
  AlphaBox       → PessimisticTtfHours
  AuditLedger    → new GxP entry (SHA256 visible)
  TelemetryHud   → latency ms

IF RiskScore >= 75:
  AlphaBox → neon-throb animation (red pulse)
  XaiRiskMonitor → "CRITICAL ANOMALY" badge
```

## Alternate Flows

**A1 — Data Readiness fails:**
```
Step 2 returns Status = "NotAcceptable"
  → API returns 422 Unprocessable Entity
  → Body: {errors: ["PACKAGING_INCOMPATIBLE: Pharma+Passive+>48h"], warnings: []}
  → ReadinessFailEvent published to Service Bus
  → UI shows error modal with errors[] list
  → Prediction does NOT execute (domain invariant)
  → AlphaBox shows "READINESS_FAILED" state
```

**A2 — Insufficient historical data:**
```
Step 4: HistoricalSelector count < 5
  → InsufficientHistoricalDataException thrown
  → API returns 422
  → Body: {error: "DATASET_TOO_SMALL: 3 records found, minimum 5 required"}
  → UI shows warning: "Insufficient data for this route/packaging/season"
```

**A3 — No active model (first time):**
```
Step 5: RetrainDecider → ShouldRetrain=true, Reason="NO_MODEL_EXISTS", Severity="Critical"
  → Retraining queued immediately
  → Step 7: PredictionEngine uses rule-based fallback (no ML model)
  → PredictionResult includes flag: ModelSource="RuleBasedFallback"
  → UI shows warning: "Prediction based on rules — ML model training in progress"
```

**A4 — SignedCommand validation fails:**
```
ReasonForChange is empty
  → ElectronicSignatureRequiredException thrown in SignedCommand constructor
  → API returns 400 Bad Request
  → Body: {error: "ReasonForChange is mandatory (FDA 21 CFR Part 11 §11.10(e))"}
  → UI: ReasonForChangeModal remains open, shows validation error
```

## Postconditions
```
✅ ShipmentProfile created with all 8 steps recorded
✅ GxP Ledger has sealed entries for all steps
✅ PredictOkEvent published to ahs.xinfer.events
✅ UI reflects current risk state
✅ AuditLedger shows new entries with SHA256 signatures
```

---

# SSS-002: Model Retraining (Automatic Trigger)

## Use Case
**Actor:** System (BackgroundService) — no human actor
**Goal:** Retrain the prediction model when criteria are met
**Precondition:** RetrainRequiredEvent received OR scheduled check triggered

## Happy Path

```
TRIGGER                  BACKGROUND SERVICE       DOMAIN                   INFRA
───────                  ──────────────────       ──────                   ─────
RetrainRequiredEvent
received via Service Bus
OR
Scheduled timer fires
(every 24h check)
                    ──→  RetrainDecisionChecker
                         Load active ModelVersion
                         Evaluate 6 criteria:
                           1. count(new records) >= 50?
                           2. New carriers/routes in dataset?
                           3. Seasonal shift detected?
                           4. AccuracyScore < 0.75?
                           5. Days since last train > 30?
                           6. No active model exists?
                         
                         IF none true → exit (no retrain needed)
                         IF any true → proceed
                         
                    ──→  TriggerRetrainHandler
                         SignedCommand{
                           SignedById: SystemActorId,
                           SignedByName: "XINFER_RETRAIN_SCHEDULER",
                           ReasonForChange: "THRESHOLD_EXCEEDED: [criteria]"
                         }
                         
                    ──→  HistoricalSelector.SelectAsync()
                         Select up to 500 compatible records
                         Apply IQR outlier removal
                         → HistoricalDataset
                         
                    ──→  ModelTrainer.TrainAsync(dataset)
                         Serialize model (AOT-safe binary)
                         Calculate AccuracyScore on holdout set
                         → ModelVersion(n+1)
                         
                    ──→  ModelVersion.Activate()
                         Deactivate previous version
                         Set IsActive = true on new version
                         → ModelActivated event → Ledger (SHA256)
                         
                    ──→  HybridCache.InvalidateAsync("model:*")
                         Clear cached model references
                         Next prediction loads new version
                         
                    ──→  GxP Ledger: ModelRetrained entry
                         {VersionNumber, RecordCount, AccuracyScore,
                          Reason, SignedByName, SHA256}
                         
                    ──→  Service Bus: ModelRetrainedEvent
                         Consumers: AHS Hive (dashboard notification)
```

## Alternate Flows

**B1 — Training fails (data quality issue):**
```
ModelTrainer throws DataIntegrityException
  → Previous model remains active
  → GxP Ledger: RetrainFailed entry with error details
  → Azure Monitor alert fired
  → Next scheduled check will retry
```

**B2 — AccuracyScore below minimum after training:**
```
New model AccuracyScore < 0.70 (minimum threshold)
  → New model NOT activated
  → Previous model remains active
  → GxP Ledger: RetrainRejected{NewScore, Threshold, Reason}
  → Manual review flagged (QualityOfficerReviewRequired event)
```

## Postconditions
```
✅ New ModelVersion active in DB
✅ HybridCache invalidated (next prediction uses new model)
✅ GxP Ledger sealed with training details
✅ AHS Hive dashboard shows new model version
```

---

# SSS-003: What-If Simulator — GxP Parameter Change

## Use Case
**Actor:** Quality Officer (requires higher authorization than Operator)
**Goal:** Simulate risk with changed parameters AND record the analysis in GxP Ledger
**Precondition:** Active ShipmentProfile exists, user has QualityOfficer role

## Happy Path

```
ACTOR                    UI (Blazor)              API                      DOMAIN                   INFRA
─────                    ───────────              ───                      ──────                   ─────
Quality Officer
opens WhatIfSimulator
on existing shipment

Changes parameter:
  InsulationType:
  PASSIVE → ACTIVE

ReasonForChangeModal
appears automatically:
  [Select template]
  [Free text reason]
  Click CONFIRM
                    ──→  ReasonForChangeModal
                         Validates reason not empty
                         
                    ──→  ApplyWhatIfChangeCommand{
                           ShipmentProfileId,
                           ParameterName: "InsulationType",
                           PreviousValue: "PassiveChamber",
                           NewValue: "ActiveReefer",
                           ReasonForChange: "Emergency reroute — heat forecast",
                           SignedById: QualityOfficerId,
                           SignedByName: "Dr. [Name]",
                           SignedAt: DateTimeOffset.UtcNow
                         }
                                          ──→  ApplyWhatIfChangeHandler
                                               Validate SignedCommand
                                               
                                          ──→  Append WhatIfParameterChanged
                                               to GxP Ledger:
                                               {ShipmentProfileId, TenantId,
                                                ParameterName, PreviousValue,
                                                NewValue, ReasonForChange,
                                                SignedById, SignedByName,
                                                SignedAt, SHA256}
                                               
                                          ──→  Re-run prediction with new parameters:
                                               New ShipmentInputDto with
                                               PackagingType = "ActiveReefer"
                                               
                                          ──→  PredictionEngine (same 8-step sequence)
                                               PassiveChamber penalty NOT applied
                                               RiskScore recalculated
                                               New XaiDna[14] generated
                                               
                                          ──→  PredictionCompleted → Ledger
                                               (linked to WhatIfParameterChanged entry)
                                               
                                    ←──  XinferResult (updated prediction)
                                    
                    ←──  200 OK
                    
Update UI:
  XaiRiskMonitor: new RiskScore (lower — Active insulation)
  AlphaBox: new TTF (longer — lower risk)
  AuditLedger: 2 new entries:
    [1] WhatIfParameterChanged (SHA256)
        "InsulationType: PassiveChamber → ActiveReefer"
        Reason: "Emergency reroute — heat forecast"
        Signed: Dr. [Name] at [timestamp]
    [2] PredictionCompleted (SHA256)
        New RiskScore, new XaiDna
```

## Alternate Flows

**C1 — Unauthorized actor (Operator tries What-If):**
```
Request arrives without QualityOfficer role claim
  → Authorization middleware returns 403 Forbidden
  → UI shows: "This action requires Quality Officer authorization"
  → No Ledger entry created (nothing happened)
```

**C2 — Same parameter value (no change):**
```
PreviousValue == NewValue
  → Domain throws WhatIfNoChangeException
  → API returns 400 Bad Request
  → Body: {error: "No change detected. What-If requires a different value."}
  → ReasonForChangeModal remains open
```

**C3 — Reason too short (< 10 characters):**
```
ReasonForChange = "test"
  → ReasonForChangeModal validation: "Reason must be at least 10 characters"
  → Command never sent to API
  → No Ledger entry (UI-level validation prevents submission)
```

## Postconditions
```
✅ WhatIfParameterChanged event sealed in GxP Ledger (SHA256)
✅ New PredictionCompleted event sealed (linked to What-If)
✅ Full audit trail: who changed what, why, when, and what the result was
✅ AuditLedger shows both entries with signatures
✅ UI reflects new risk state with updated components
✅ FDA auditor can reconstruct the full decision chain from Ledger alone
```

---

# SSS-004: GxP Audit Export (FDA Inspector / QA Auditor)

## Use Case
**Actor:** FDA Inspector / QA Auditor / Quality Officer
**Goal:** Export complete, tamper-evident audit trail for a shipment or time period
**Precondition:** Actor has AuditExport role claim, shipment exists in system

## Happy Path

```
ACTOR                    UI (Blazor)              API                      DOMAIN                   INFRA
─────                    ───────────              ───                      ──────                   ─────
Inspector opens
Audit Export panel
in AHS Hive

Selects filter:
  ShipmentProfileId OR
  DateRange: [from, to]
  Format: PDF | CSV | JSON
  
Clicks EXPORT_AUDIT_TRAIL
                    ──→  Validate filter params
                         Show progress indicator
                         
                    ──→  GET /api/xinfer/audit/export
                         ?shipmentId={id}
                         &format=PDF
                         &signedById={inspectorId}
                         Headers: Authorization: Bearer [token]
                         
                                          ──→  AuditExportHandler
                                               Verify AuditExport role claim
                                               Log export request to Ledger:
                                               {ActorId, ActorName, Filter,
                                                RequestedAt, SHA256}
                                               
                                          ──→  Dapper query: ledger_entries
                                               WHERE tenant_id = @tenantId
                                               AND aggregate_id = @shipmentId
                                               ORDER BY sequence ASC
                                               
                                          ──→  LedgerHasher.VerifyChain(entries)
                                               Verify SHA256 chain integrity
                                               IF chain broken → flag in export
                                               
                                          ──→  Build export payload:
                                               For each ledger entry:
                                                 {Sequence, EventType,
                                                  PayloadJson (human-readable),
                                                  ActorName, OccurredAt (UTC),
                                                  EntryHash (SHA256),
                                                  HmacSeal,
                                                  PreviousHash,
                                                  ChainValid: true|false}
                                               
                                          ──→  IF Format = PDF:
                                               Generate PDF with:
                                                 - Cover page: ShipmentId, TenantId,
                                                   ExportedAt, ExportedBy, RecordCount
                                                 - Chain verification summary
                                                 - Entry table (all fields)
                                                 - Hash verification footer
                                                 - Digital signature of export itself
                                                   
                                               IF Format = CSV:
                                               Generate CSV with all fields as columns
                                               + ChainValid column per row
                                               
                                               IF Format = JSON:
                                               Return structured JSON array
                                               
                                          ──→  Append ExportCompleted to Ledger:
                                               {ExportId, ActorId, ActorName,
                                                RecordCount, Format,
                                                ChainValid, ExportedAt, SHA256}
                                               (audit of the audit export itself)
                                               
                                    ←──  File stream (PDF/CSV/JSON)
                                         Content-Disposition: attachment
                                         Content-Type: application/pdf|text/csv|application/json
                                         
                    ←──  File download triggered
                    
                         Browser downloads file:
                         "xinfer-audit-{shipmentId}-{timestamp}.pdf"
                         
Inspector reviews:
  - Each entry shows SHA256 hash
  - ChainValid = true for all entries
  - Cover page shows: "Chain integrity verified ✅"
  - If any entry tampered: "⚠️ Chain break detected at sequence N"
```

## Alternate Flows

**D1 — Chain integrity broken:**
```
LedgerHasher.VerifyChain() returns false at sequence N
  → Export proceeds (do not hide the breach)
  → Affected entries flagged: ChainValid = false
  → Cover page shows: "⚠️ INTEGRITY ALERT: Chain break at sequence N"
  → Azure Monitor alert fired immediately
  → ExportCompleted Ledger entry includes: ChainBreakDetected = true
  → Inspector sees exactly which entries are suspect
```

**D2 — Date range returns 0 records:**
```
No ledger entries in requested range
  → API returns 404 Not Found
  → Body: {error: "No audit records found for the specified filter"}
  → No export file generated
  → Export request still logged in Ledger (actor tried to export)
```

**D3 — Actor lacks AuditExport role:**
```
Token does not contain AuditExport claim
  → Authorization middleware returns 403 Forbidden
  → Body: {error: "AuditExport role required for this operation"}
  → No export generated
  → Unauthorized attempt logged in Ledger with actor identity
```

**D4 — Large export (> 10,000 entries):**
```
RecordCount > 10,000
  → Synchronous response not feasible
  → API returns 202 Accepted
  → Body: {exportJobId, estimatedSeconds}
  → BackgroundService generates export async
  → Actor polls: GET /api/xinfer/audit/export/{jobId}/status
  → When ready: download URL returned (Azure Blob, SAS token, 1h expiry)
```

## Postconditions
```
✅ Export file downloaded by actor
✅ Every entry shows SHA256 hash visible to inspector
✅ Chain integrity status explicit (verified or broken)
✅ ExportCompleted entry sealed in GxP Ledger (meta-audit)
✅ FDA inspector can verify file independently using SHA256 tool
✅ Export itself has no expiry — file is self-contained evidence
```

---

# SSS-005: Tenant Onboarding (System Admin)

## Use Case
**Actor:** System Administrator (AHS internal)
**Goal:** Onboard a new tenant so they can use Xinfer with full isolation
**Precondition:** Tenant contract signed, Entra ID app registration created

## Happy Path

```
ACTOR                    ADMIN TOOL / CLI         API                      INFRA                    DB
─────                    ────────────────         ───                      ─────                    ──
System Admin
runs onboarding script:

.\Onboard-Tenant.ps1
  -TenantSlug "pharma-corp-eu"
  -TenantName "PharmaCorpEU"
  -Plan "Enterprise"
  -IsolationMode "Isolated"
  -AzureRegion "westeurope"
  -AdminEmail "admin@pharmacorp.eu"
                    ──→  Validate parameters
                         Check TenantSlug unique
                         Check AzureRegion allowed
                         
                    ──→  POST /api/admin/tenants
                         {TenantSlug, TenantName,
                          Plan, IsolationMode,
                          AzureRegion, AdminEmail}
                         Headers: X-Admin-Key: [internal key]
                         
                                          ──→  TenantOnboardingHandler
                                               Generate TenantId (Guid)
                                               
                                          ──→  IF IsolationMode = Shared:
                                               Use existing Cell DB
                                               RLS via set_config handles isolation
                                               SchemaName = "public"
                                               
                                               IF IsolationMode = Isolated:
                                               Create schema in Cell DB:
                                                 CREATE SCHEMA pharma_corp_eu;
                                                 SET search_path TO pharma_corp_eu;
                                               SchemaName = "pharma_corp_eu"
                                               
                                          ──→  Run Cell migrations in schema:
                                               Execute 001_Xinfer_InitialCreate.sql
                                               In target schema (Isolated)
                                               Or in public schema (Shared)
                                               
                                          ──→  Register tenant in tenants table:
                                               INSERT INTO tenants
                                               {TenantId, TenantSlug, TenantName,
                                                Plan, IsolationMode, SchemaName,
                                                AzureRegion, CreatedAt, IsActive}
                                               
                                          ──→  Configure Entra ID:
                                               Add custom claims to app registration:
                                                 tenant_id: {TenantId}
                                                 tenant_slug: "pharma-corp-eu"
                                                 isolation_mode: "Isolated"
                                                 ahs_role: "Operator"
                                               
                                          ──→  Seed reference data:
                                               INSERT default ZoneProfiles
                                               INSERT default RouteRiskProfiles
                                               (pharma defaults: 2-8°C setpoints)
                                               
                                          ──→  Send welcome email:
                                               To: admin@pharmacorp.eu
                                               Subject: "AHS Xinfer — Tenant Ready"
                                               Body: login URL + initial credentials
                                               
                                          ──→  GxP Ledger: TenantOnboarded event
                                               {TenantId, TenantSlug, Plan,
                                                IsolationMode, OnboardedAt,
                                                OnboardedBy: AdminId, SHA256}
                                               
                                    ←──  201 Created
                                         {TenantId, TenantSlug,
                                          LoginUrl, SchemaName,
                                          IsolationMode}
                                          
Script output:
  ✅ Tenant ID: {guid}
  ✅ Schema: pharma_corp_eu (Isolated mode)
  ✅ Migrations: applied
  ✅ Entra ID: claims configured
  ✅ Welcome email: sent
  ✅ Login URL: https://hive.ahs.com/login?tenant=pharma-corp-eu
```

## Alternate Flows

**E1 — TenantSlug already exists:**
```
SELECT count(*) FROM tenants WHERE tenant_slug = @slug > 0
  → API returns 409 Conflict
  → Body: {error: "Tenant slug 'pharma-corp-eu' already registered"}
  → Script exits with error code
  → No schema created, no Entra ID changes
```

**E2 — Shared → Isolated upgrade (existing tenant):**
```
Tenant was onboarded as Shared, now requests Isolated
  → Different endpoint: PUT /api/admin/tenants/{id}/isolation
  → Steps:
    1. Create new schema: pharma_corp_eu
    2. Run migrations in new schema
    3. Migrate existing data:
       INSERT INTO pharma_corp_eu.[table]
       SELECT * FROM public.[table]
       WHERE tenant_id = @tenantId
    4. Verify row counts match
    5. Update tenants table: IsolationMode=Isolated, SchemaName=pharma_corp_eu
    6. DELETE from public.[table] WHERE tenant_id = @tenantId
    7. Zero downtime — TenantSessionInterceptor switches schema transparently
  → GxP Ledger: IsolationUpgraded event (before + after state)
```

**E3 — Migration fails mid-execution:**
```
SQL error during migration
  → Transaction rolled back (all DDL in explicit transaction)
  → Schema dropped if created: DROP SCHEMA IF EXISTS pharma_corp_eu CASCADE
  → API returns 500 Internal Server Error
  → Admin script shows exact failed migration
  → Retry is safe (idempotent migrations)
```

**E4 — Entra ID configuration fails:**
```
Microsoft Graph API returns error
  → DB changes already committed (tenant registered, schema created)
  → API returns 207 Multi-Status:
    {tenantCreated: true, entraIdConfigured: false, error: "Graph API timeout"}
  → Admin must manually configure Entra ID claims
  → Script shows manual steps to complete configuration
```

## Postconditions
```
✅ Tenant exists in tenants table with correct IsolationMode
✅ Cell migrations applied in correct schema (public or tenant-specific)
✅ Entra ID claims configured (tenant_id, tenant_slug, ahs_role)
✅ TenantSessionInterceptor will correctly route queries for this tenant
✅ GxP Ledger has TenantOnboarded entry
✅ Admin received login URL
✅ Tenant can immediately start submitting shipments
```

---

## SSS Index (Complete)

| ID | Use Case | Actor | Complexity | Status |
|---|---|---|---|---|
| SSS-001 | Shipment Risk Evaluation | Operator / QA Analyst | High | ✅ Defined |
| SSS-002 | Model Retraining | System (BackgroundService) | Medium | ✅ Defined |
| SSS-003 | What-If Parameter Change | Quality Officer | High (GxP) | ✅ Defined |
| SSS-004 | GxP Audit Export | FDA Inspector / QA Auditor | Medium | ✅ Defined |
| SSS-005 | Tenant Onboarding | System Admin | Medium | ✅ Defined |

---
*System Sequence Specifications — AHS.Cell.Xinfer v1.1*
*All 5 use cases defined. Add new SSS when new use cases are identified.*
*Input for C2 handler design and AG implementation*
