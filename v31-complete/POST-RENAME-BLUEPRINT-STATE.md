# AHS Blueprint — Post-Rename State
## Version: V3.1.2 | Date: 2026-03 | Status: Active

## What changed in V3.1.2

```
AHS.Cell.ColdChain.* → AHS.Cell.Xinfer.*
AHS.Web.UI           → AHS.Web.Hive
C1 + C2              → C1 consolidated (single Google AI Studio instance)
```

## Next steps after rename

### Immediate (do in order)
```
1. git commit checkpoint
2. AG executes PM-RENAME-ColdChain-to-Xinfer.md
3. Verify: dotnet build → 0 errors
4. AG executes PM-RENAME-WebUI-to-Hive.md
5. Verify: dotnet build → 0 errors
6. git commit "refactor: Xinfer + Hive (Blueprint V3.1.2)"
7. Replace C1 System Instructions with C1-CONSOLIDATED
8. Decommission C2 Google AI Studio instance
```

### Then — implement new Xinfer Cell Blueprint (7 Cells)
```
CELL-SHIPMENT-INPUT       → captures intrinsic + environmental + operational data
CELL-DATA-READINESS       → evaluates quality and compatibility
CELL-HISTORICAL-SELECTOR  → selects relevant historical data
CELL-MODEL-RETRAIN-DECIDER → decides if retraining needed (does NOT train)
CELL-MODEL-TRAINER        → retrains when decider approves
CELL-MODEL-PREDICTOR      → predicts risk using active model
CELL-RECOMMENDER          → generates actionable recommendations
```

### Dashboard fixes still pending
```
□ Scroll in ORACLE_RISK_LENS_PRO grid (verify AG fixed it)
□ INYECTAR_SIMULACIÓN button wiring (verify AG fixed it)
□ WhatIfSimulator component visibility after last AG session
```

### Future Cells (when market demands)
```
AHS.Cell.AssetManager  → GxP asset lifecycle
AHS.Cell.FinTracker    → multi-currency cost tracking
AHS.Cell.ShopifyBridge → e-commerce integration
```

### .NET Aspire (when 2+ Cells active)
```
AHS.AppHost project in 📁 Infrastructure
Orchestrates: Xinfer API + PostgreSQL + Redis + Service Bus Emulator
Dashboard: localhost:15888
```

## Files in v31-complete/ ready for use

```
C1-CONSOLIDATED-SYSTEM-INSTRUCTIONS.md  → paste into Google AI Studio C1
                                           replaces both C1.md and C2.md
PM-RENAME-ColdChain-to-Xinfer.md        → send to AG first
PM-RENAME-WebUI-to-Hive.md              → send to AG second
BLUEPRINT-SUPPLEMENT-V3.1.2.md         → save to 00_Constitution\
AHS-SKILLS-DISTRIBUTION-MAP.md         → updated reference
```

## Ecosystem identity (final)

```
AHS Hive     = the organism (shell)
AHS Xinfer   = excursion inference engine (X = Excursion)
Sovereign Elite = the exoskeleton (design system)
GxP Ledger   = immutable memory
AOT          = exists without JIT dependency
```
