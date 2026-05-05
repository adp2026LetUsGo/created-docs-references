# AHS Skills — Mapa de Distribución Definitivo
## Blueprint V3.1.2 | Fecha: 2026-03-25 | Naming: Xinfer + Hive

---

## SISTEMA C1 — Google AI Studio (System Instructions)
**Rol:** Architect & PM — razona dominio, estrategia, producto

### Orden de pegado en System Instructions (de arriba a abajo)

```
1. c1-architect-pm                  ← rol e identidad de C1
2. brainstorming                    ← proceso antes de diseñar
3. multi-agent-brainstorming        ← validación antes del Prompt Maestro
4. ddd-strategic-design             ← Bounded Contexts, Aggregates, Ubiquitous Language
5. regulatory-compliance-matrix     ← FDA, GDPR, HACCP, ISO 27001
6. ahs-product-cell-canvas          ← Cell Viability Test, PRD template
7. c4-documentation-standard        ← C4 L1-L2 Mermaid (C1 produce L1 y L2)
```

---

## SISTEMA C2 — Google AI Studio (System Instructions)
**Rol:** Lead Engineer — diseña técnico, produce Prompt Maestro

### Orden de pegado en System Instructions (de arriba a abajo)

```
1. c2-lead-engineer                 ← rol e identidad de C2
2. cqrs-clean-architecture-patterns ← EF Core vs Dapper, handlers, domain services
3. cell-integration-patterns        ← Outbox, Saga, Service Bus, cross-cell testing
4. prompt-engineering-ag            ← Prompt Maestro template 9 secciones
5. c4-documentation-standard        ← C4 L3-L4 (C2 produce L3 y L4)
```

---

## AG — Antigravity (disco: .agent\skills\)
**Rol:** Executor — genera archivos físicos de código

### Distribución por directorio

```
.agent\skills\
│
├── 00_Constitution\
│   ├── Blueprint.MD                          ← ya existe
│   └── Blueprint_Supplement_V3.1.1.MD        ← AÑADIR
│
├── 01_Core\
│   ├── brainstorming.md                      ← ya existe (conservar)
│   ├── Micro-SaaS Launcher.md                ← ya existe (conservar)
│   ├── product-manager.md                    ← ya existe (conservar)
│   ├── product-manager-toolkit.md            ← ya existe (conservar)
│   ├── SaaS MVP Launcher.md                  ← ya existe (conservar)
│   ├── SaaS-Learned-Factors.md               ← ya existe (conservar)
│   ├── native-aot\SKILL.md                   ← AÑADIR
│   ├── simd-vectorization-csharp\SKILL.md    ← AÑADIR
│   ├── sha256-cryptographic-sealing\SKILL.md ← AÑADIR
│   └── regulatory-compliance-matrix\SKILL.md ← AÑADIR
│
├── 02_Architecture\
│   ├── Antigravity Workflows.md              ← ya existe (conservar)
│   ├── antigravity-skill-orchestrator.md     ← ya existe (conservar)
│   ├── CQRS Implementation.md               ← ya existe (conservar)
│   ├── comm-architect-review.md             ← ya existe (conservar)
│   ├── comm-architecture-patterns.md        ← ya existe (conservar)
│   ├── DDD Context Mapping.md               ← ya existe (conservar)
│   ├── ahs-dotnet-architect.md              ← REEMPLAZAR con versión fusionada V3.1
│   ├── ahs-cellular-architecture\SKILL.md   ← AÑADIR
│   ├── c4-documentation-standard\SKILL.md   ← AÑADIR
│   ├── ddd-strategic-design\SKILL.md        ← AÑADIR
│   ├── cqrs-clean-architecture-patterns\SKILL.md ← AÑADIR
│   ├── cell-integration-patterns\SKILL.md   ← AÑADIR
│   └── multi-agent-brainstorming\SKILL.md   ← AÑADIR
│
├── 03_Backend\
│   ├── Clean Code.md                        ← ya existe (conservar ✅)
│   ├── database-architect.md                ← ya existe (conservar ✅ — agnóstico al stack)
│   ├── DotNet10-SaaS-Core.md               ← REEMPLAZAR con DotNet10-SaaS-Core-UPDATED.md
│   ├── Hybrid-Persistence-Standard.md       ← REEMPLAZAR con Hybrid-Persistence-Standard-UPDATED.md
│   ├── multitenancy\SKILL.md               ← AÑADIR
│   ├── gxp-ledger-eventsourcing\SKILL.md   ← AÑADIR
│   ├── industrial-cold-chain-logic\SKILL.md ← AÑADIR
│   ├── logistics-oracle-xai\SKILL.md        ← AÑADIR
│   ├── ahs-testing-quality\SKILL.md         ← AÑADIR
│   └── azure-devops-coldchain\SKILL.md      ← AÑADIR
│
├── 04_UI_UX\
│   ├── Antigravity-UI-and-Motion Design Expert.md ← ya existe (conservar ✅ — motion/animation complementario)
│   ├── blazor-razor-expert.md               ← REEMPLAZAR con versión .NET 10 (de /skills/)
│   └── tailwind-glassmorphism-system\SKILL.md ← AÑADIR
│
└── 05_Workflow\                             ← CREAR directorio nuevo
    ├── prompt-engineering-ag\SKILL.md       ← AÑADIR
    └── ahs-cell-template\SKILL.md           ← AÑADIR
```

---

## Resumen de acciones — ANÁLISIS COMPLETO ✅

| Acción | Cantidad | Skills |
|---|---|---|
| **Conservar sin tocar** | 13 | brainstorming, Micro-SaaS Launcher, product-manager, product-manager-toolkit, SaaS MVP Launcher, SaaS-Learned-Factors, Antigravity Workflows, antigravity-skill-orchestrator, CQRS Implementation, comm-architect-review, comm-architecture-patterns, DDD Context Mapping, Clean Code, database-architect, Antigravity-UI-and-Motion |
| **Actualizar contenido** | 3 | SaaS-Learned-Factors (nomenclatura + 2 lecciones nuevas), DotNet10-SaaS-Core (estructura V3.1 + sin MediatR), Hybrid-Persistence-Standard (PostgreSQL only + nomenclatura Cells) |
| **Reemplazar** | 3 | ahs-dotnet-architect → UPDATED, blazor-razor-expert → .NET 10, multitenancy → V3.1 |
| **Añadir en disco (AG)** | 19 | Ver árbol de directorios arriba |
| **Añadir en C1 System Instructions** | 7 | c1-architect-pm, brainstorming, multi-agent-brainstorming, ddd-strategic-design, regulatory-compliance-matrix, ahs-product-cell-canvas, c4-documentation-standard |
| **Añadir en C2 System Instructions** | 5 | c2-lead-engineer, cqrs-clean-architecture-patterns, cell-integration-patterns, prompt-engineering-ag, c4-documentation-standard |
| **Crear directorio nuevo** | 1 | 05_Workflow\ |
| **Añadir en 00_Constitution** | 4 docs | Blueprint_Supplement_V3.1.1, AHS-ADR-SET-001-008, AHS-PRD-AND-TECHNOLOGY-RADAR, AHS-SKILLS-DISTRIBUTION-MAP |

---

## Análisis de skills existentes — resultado final

| Skill | Directorio | Veredicto | Motivo |
|---|---|---|---|
| brainstorming.md | 01_Core | ✅ Conservar | Proceso agnóstico, cero conflicto |
| Micro-SaaS Launcher.md | 01_Core | ✅ Conservar | Estrategia pre-Cell, complementario |
| product-manager.md | 01_Core | ✅ Conservar | PM genérico, 30+ frameworks, cero conflicto |
| product-manager-toolkit.md | 01_Core | ✅ Conservar | RICE, entrevistas, PRD templates, cero conflicto |
| SaaS MVP Launcher.md | 01_Core | ✅ Conservar | Stack genérico complementario |
| SaaS-Learned-Factors.md | 01_Core | 🔄 Actualizar | Nomenclatura V2→V3.1 + 2 lecciones AOT nuevas |
| Antigravity Workflows.md | 02_Architecture | ✅ Conservar | Orquestador multi-fase, agnóstico |
| antigravity-skill-orchestrator.md | 02_Architecture | ✅ Conservar | Meta-skill, guardrail complejidad, agnóstico |
| CQRS Implementation.md | 02_Architecture | ✅ Conservar | CQRS genérico, complementa el AHS-específico |
| comm-architect-review.md | 02_Architecture | ✅ Conservar | Review independiente de alta calidad |
| comm-architecture-patterns.md | 02_Architecture | ✅ Conservar | Patterns genéricos, nota sobre DBOS vs Outbox |
| DDD Context Mapping.md | 02_Architecture | ✅ Conservar | Tuyo (source: self), operativo, complementario |
| ahs-dotnet-architect.md | 02_Architecture | 🔄 Reemplazar | 3 divergencias V3.1: Vertical Slice→Clean Arch, MQTT→Adapter/Port, YAML→Prompt Maestro |
| Clean Code.md | 03_Backend | ✅ Conservar | Uncle Bob puro, agnóstico, valor permanente |
| database-architect.md | 03_Backend | ✅ Conservar | Agnóstico al stack, complementa multitenancy |
| DotNet10-SaaS-Core.md | 03_Backend | 🔄 Reemplazar | Estructura dirs obsoleta + MediatR + Shared Kernel |
| Hybrid-Persistence-Standard.md | 03_Backend | 🔄 Reemplazar | Excel/CSV como backend obsoleto + nomenclatura |
| Antigravity-UI-and-Motion Design Expert.md | 04_UI_UX | ✅ Conservar | Motion/animation complementario a Sovereign Elite |
| blazor-razor-expert.md | 04_UI_UX | 🔄 Reemplazar | .NET 8 → .NET 10, falta PersistentState, ValidatableType, AOT |

---

## Regla de decisión (para futuros skills)

```
¿Responde "qué construir y por qué"?     → C1 System Instructions
¿Responde "cómo diseñar técnicamente"?   → C2 System Instructions
¿Responde "cómo escribir el código"?     → AG en disco
¿Aplica a los tres?                      → AG en disco es suficiente
                                           (C2 lo referencia en el Prompt Maestro)
```

---

## Archivos de referencia (v31-complete/)

| Archivo | Usar cuando |
|---|---|
| `ahs-dotnet-architect-UPDATED.skill` | Reemplazar `ahs-dotnet-architect.md` en 02_Architecture |
| `blazor-razor-expert.skill` (de /skills/) | Reemplazar `blazor-razor-expert.md` en 04_UI_UX |
| `DotNet10-SaaS-Core-UPDATED.md` | Reemplazar `DotNet10-SaaS-Core.md` en 03_Backend |
| `Hybrid-Persistence-Standard-UPDATED.md` | Reemplazar `Hybrid-Persistence-Standard.md` en 03_Backend |
| `ahs-cellular-architecture.skill` (v31-complete/) | Instalar en 02_Architecture (versión con nota Supplement) |
