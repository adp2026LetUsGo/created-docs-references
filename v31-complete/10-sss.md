# 10 — System Sequence Specifications (SSS)
## AHS.Cell.Xinfer | Version: 1.1 | Blueprint: V3.1.2

This document defines the end-to-end interaction flows between actors
and the Xinfer Cell for each use case. Each SSS maps directly to a
command handler in the Application layer.

## Relationship to Other Docs
```
02-use-cases.md    → high-level flows (what happens)
10-sss.md          → detailed flows (who calls what, in what order,
                      with what data, and what happens in each error case)
```

---

## SSS-001: Shipment Risk Evaluation

**Actor:** Logistics Operator / QA Analyst
**Handler:** `SubmitShipmentHandler`
**Precondition:** ≥5 historical records exist for route+packaging+season

### Happy Path
```
Operator fills WhatIfSimulator form
  → INYECTAR_SIMULACIÓN clicked
  → POST /api/xinfer/evaluate {ShipmentInputDto + ReasonForChange}
  → SubmitShipmentHandler validates SignedCommand
  → Step 1: ShipmentProfile.Create() → ShipmentProfileCreated → Ledger
  → Step 2: ReadinessValidator → ReadinessState
      NotAcceptableState → 422 + ReadinessFailEvent → Service Bus
      RiskyState / AcceptableState → continue
  → Step 3: DivergenceDetector → DivergenceReport → Ledger
  → Step 4: HistoricalSelector → HistoricalDataset
      count < 5 → InsufficientHistoricalDataException → 422
  → Step 5: RetrainDecider → RetrainDecision → Ledger
      ShouldRetrain=true → RetrainRequiredEvent → Service Bus (async)
  → Step 6: (async) BackgroundService retrains if queued
  → Step 7: PredictionEngine → PredictionResult (14 XAI factors)
      XinferSequenceViolationException if CanPredict=false
  → Step 8: Recommender → Recommendations[]
  → Outbox: PredictOkEvent → Service Bus (atomic with DB)
  → 200 OK {PredictionResultDto}
  → UI: XaiRiskMonitor, AlphaBox, AuditLedger updated
```

### Alternate Flows
```
A1: ReadinessState = NotAcceptableState → 422, prediction blocked
A2: Dataset < 5 records → 422, message: "DATASET_TOO_SMALL"
A3: No active model → rule-based fallback prediction, flag in response
A4: ReasonForChange empty → 400, ElectronicSignatureRequiredException
```

---

## SSS-002: Model Retraining (Automatic)

**Actor:** System (BackgroundService)
**Handler:** `TriggerRetrainHandler`
**Precondition:** RetrainRequiredEvent received OR scheduled check

### Happy Path
```
BackgroundService receives trigger
  → Load active ModelVersion
  → Evaluate 6 criteria (new records, season, carrier, accuracy, time, no model)
  → IF none → exit
  → TriggerRetrainHandler {SystemActorId, "XINFER_RETRAIN_SCHEDULER", reason}
  → HistoricalSelector → dataset (max 500 records, IQR cleaned)
  → ModelTrainer.TrainAsync(dataset) → new ModelVersion
  → Evaluate AccuracyScore ≥ 0.70 threshold
      < 0.70 → NOT activated, QualityOfficerReviewRequired event
      ≥ 0.70 → ModelVersion.Activate() → ModelActivated → Ledger
  → HybridCache.InvalidateAsync("model:*")
  → ModelRetrainedEvent → Service Bus
```

### Alternate Flows
```
B1: DataIntegrityException → previous model stays active, Azure Monitor alert
B2: AccuracyScore < 0.70 → new model rejected, manual review required
```

---

## SSS-003: What-If Parameter Change (GxP)

**Actor:** Quality Officer (requires QualityOfficer role)
**Handler:** `ApplyWhatIfChangeHandler`
**Precondition:** Active ShipmentProfile exists

### Happy Path
```
Quality Officer changes parameter in WhatIfSimulator
  → ReasonForChangeModal appears (mandatory)
  → Confirm clicked with valid reason (≥10 chars)
  → ApplyWhatIfChangeCommand {ShipmentProfileId, ParameterName,
      PreviousValue, NewValue, ReasonForChange, SignedById, SignedByName}
  → ApplyWhatIfChangeHandler
  → Append WhatIfParameterChanged → Ledger (SHA256 sealed)
  → Re-run full prediction with new parameters (same 8-step sequence)
  → PredictionCompleted → Ledger (linked to WhatIf entry)
  → 200 OK {updated XinferResult}
  → UI: XaiRiskMonitor, AlphaBox updated (2 new AuditLedger entries)
```

### Alternate Flows
```
C1: Actor lacks QualityOfficer role → 403 Forbidden, no Ledger entry
C2: PreviousValue == NewValue → 400, WhatIfNoChangeException
C3: Reason < 10 chars → UI validation, command never sent
```

---

## SSS-004: GxP Audit Export

**Actor:** FDA Inspector / QA Auditor / Quality Officer (AuditExport role)
**Handler:** `AuditExportHandler`

### Happy Path
```
Inspector selects filter (ShipmentId OR DateRange) + Format (PDF/CSV/JSON)
  → GET /api/xinfer/audit/export?shipmentId=...&format=PDF
  → AuditExportHandler verifies AuditExport role
  → Log export request to Ledger
  → Dapper query: SELECT * FROM ledger_entries ORDER BY sequence
  → LedgerHasher.VerifyChain(entries)
      Chain broken → flag entries, include in export with warning
  → Generate file with ChainValid per entry
  → Append ExportCompleted → Ledger (meta-audit)
  → Stream file download
```

### Alternate Flows
```
D1: Chain broken → export proceeds, entries flagged, Azure Monitor alert
D2: 0 records found → 404
D3: Actor lacks AuditExport role → 403, attempt logged
D4: > 10,000 entries → 202 Accepted, async via Azure Blob + SAS URL
```

---

## SSS-005: Tenant Onboarding

**Actor:** System Administrator
**Script:** `Onboard-Tenant.ps1`

### Happy Path
```
Admin runs script: -TenantSlug -Plan -IsolationMode -AzureRegion
  → POST /api/admin/tenants
  → TenantOnboardingHandler
  → IF IsolationMode=Shared → SchemaName="public", RLS handles isolation
  → IF IsolationMode=Isolated → CREATE SCHEMA {slug}, run migrations
  → INSERT into tenants table {TenantId, TenantSlug, IsolationMode, SchemaName}
  → Configure Entra ID claims (tenant_id, tenant_slug, ahs_role)
  → Seed default reference data (ZoneProfiles, RouteRiskProfiles)
  → Send welcome email
  → TenantOnboarded → Ledger
  → 201 Created {TenantId, LoginUrl, SchemaName}
```

### Alternate Flows
```
E1: TenantSlug exists → 409 Conflict, no schema created
E2: Shared→Isolated upgrade → PUT /api/admin/tenants/{id}/isolation
    Zero downtime migration: new schema → migrate data → update tenant record
E3: Migration fails → rollback, DROP SCHEMA if created, 500 + retry instructions
E4: Entra ID fails → 207 Multi-Status, manual steps provided
```

---

## SSS Index

| ID | Use Case | Actor | Handler | Status |
|---|---|---|---|---|
| SSS-001 | Shipment Risk Evaluation | Operator | SubmitShipmentHandler | ✅ |
| SSS-002 | Model Retraining | System | TriggerRetrainHandler | ✅ |
| SSS-003 | What-If Parameter Change | Quality Officer | ApplyWhatIfChangeHandler | ✅ |
| SSS-004 | GxP Audit Export | FDA Inspector | AuditExportHandler | ✅ |
| SSS-005 | Tenant Onboarding | System Admin | TenantOnboardingHandler | ✅ |
