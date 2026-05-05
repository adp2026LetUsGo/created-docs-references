# AHS.SaaS — Inventario de Documentos
## Blueprint V3.1.2 | Generado: 2026-04-25
## Total: 32 archivos MD + 9 skills

---

## TABLA MAESTRA DE DOCUMENTOS

| # | Archivo | Dónde Colocar | Naturaleza | Uso y Propósito |
|---|---|---|---|---|
| 1 | `BLUEPRINT-V3.1.2-UNIFIED.md` | `docs/00_Constitution/` | **Constitución del ecosistema** | Documento madre. Define las leyes que gobiernan CUALQUIER Cell: 5 guardrails, naming framework, tech stack aprobado, ADR index. NO cambia cuando se añade una Cell. Solo cambia con un nuevo ADR. |
| 2 | `BLUEPRINT-SUPPLEMENT-V3.1.2.md` | `docs/00_Constitution/` | **Suplemento constitucional** | Resuelve 3 tensiones arquitectónicas: Tiered Isolation, BFF Pattern, Sovereign Elite enforcement. Incluye Naming Framework constitucional. Supersedido por el Unified — conservar como referencia. |
| 3 | `BLUEPRINT-SUPPLEMENT-V3.1.1.md` | `docs/00_Constitution/archive/` | **Versión anterior — archivar** | Versión previa del supplement. Conservar como historial de decisiones. No usar activamente. |
| 4 | `AHS-ADR-SET-001-008.md` | `docs/00_Constitution/` | **ADRs fundacionales** | 8 Architecture Decision Records: Database-per-Cell, AOT, Service Bus, PostgreSQL, HybridCache, SignedCommand, Contracts versioning, UI boundaries. Referencia permanente. |
| 5 | `ADR-009-architectural-alignment.md` | `docs/00_Constitution/` | **ADR transversal** | Define estándares de alignment entre Cells: CI enforcement, contracts governance, UI alignment, operational alignment. Aplica a TODAS las Cells. |
| 6 | `PRD-009-prd-alignment.md` | `docs/00_Constitution/` | **Estrategia PRD** | Define cómo cada Cell PRD debe referenciar ADRs, alinear features con el Blueprint, y mantener consistencia de dominio. Aplica a TODOS los PRDs. |
| 7 | `AHS-CELL-CATALOG.md` | `docs/00_Constitution/` | **Inventario vivo de Cells** | Registra qué Cells existen, en qué estado, qué hacen y su historia. EVOLUCIONA cuando se añade/renombra/retira una Cell. La Constitución NO cambia — este catálogo sí. |
| 8 | `ATOMIC-BLUEPRINT-Xinfer.md` | `src/Cells/Xinfer/docs/` | **Constitución de la Cell Xinfer** | Las 10 secciones que definen Xinfer específicamente: Identity, Mission, Domain Model, Execution Sequence, Regulatory Scope, Integration Map, Data Schema, Technical Constraints, UI Spec, Quality Gates. V1.1 post-fix. |
| 9 | `SSS-Xinfer.md` | `src/Cells/Xinfer/docs/` | **Especificaciones de secuencia** | 5 System Sequence Specifications detalladas: flujos actor→UI→API→Domain→Infra para cada caso de uso con flujos alternos y postcondiciones. Input crítico para C2. |
| 10 | `10-sss.md` | `src/Cells/Xinfer/docs/` | **SSS compacto (formato docs/)** | Versión condensada de SSS-Xinfer.md optimizada para vivir en la carpeta docs/ junto a los 00-09 archivos de Xinfer. Mismo contenido, formato más conciso. |
| 11 | `C1-SYSTEM-INSTRUCTIONS.md` | **Google AI Studio C1** | **System Instructions de C1** | 8 skills concatenados para pegar en Google AI Studio instancia C1. Contiene: identidad, diseño, validación, DDD, compliance, Cell Canvas, C4, multitenancy. 1,792 líneas. |
| 12 | `C2-SYSTEM-INSTRUCTIONS.md` | **Google AI Studio C2** | **System Instructions de C2** | 5 skills + Swarm Orchestration Directive para pegar en Google AI Studio instancia C2. Contiene: identidad, CQRS, integración, Prompt Engineering, C4. 2,144 líneas. Versión SWARM-INTEGRATED. |
| 13 | `HANDOFF-C1.md` | **Pegar al inicio de sesión C1** | **Contexto de sesión para C1** | Documento que se pega al inicio de cada sesión con C1. Contiene: contexto del proyecto, estado de Xinfer, reglas de diseño, panel multi-agente, roadmap. NO va en System Instructions. |
| 14 | `HANDOFF-C2.md` | **Pegar al inicio de sesión C2** | **Contexto de sesión para C2** | Documento que se pega al inicio de cada sesión con C2. Contiene: estado técnico, acciones pendientes, reglas de Prompt Maestro, quality gates estándar. NO va en System Instructions. |
| 15 | `HANDOFF-AG.md` | **Pegar al inicio de sesión AG** | **Contexto de sesión para AG** | Documento que se pega al inicio de cada sesión con Antigravity. Contiene: qué existe (no regenerar), acciones pendientes en orden, reglas críticas AOT, paths exactos. |
| 16 | `AHS-MASTER-HANDOFF.md` | **Referencia general** | **Visión completa del proyecto** | Documento maestro que resume TODO el proyecto: historia, estado actual, pending actions, detalles técnicos, roadmap. Usar para iniciar sesiones con Claude o como referencia ejecutiva. |
| 17 | `POST-RENAME-BLUEPRINT-STATE.md` | `docs/00_Constitution/archive/` | **ARCHIVADO — histórico** | Era el "qué hacer después del rename". Todas las acciones ya fueron ejecutadas. Conservar como registro histórico de decisiones. No usar activamente. |
| 18 | `PM-CELL-CHASSIS.md` | `docs/Prompts AG/` | **Prompt Maestro — scaffold universal** | AG lo ejecuta UNA VEZ al crear cualquier Cell nueva. Implementa los 3 componentes base: Tenant Isolation, Outbox Pattern, SignedCommand. Usa placeholders [CellName]. |
| 19 | `PM-CELL-Xinfer-v2.md` | `docs/Prompts AG/` | **Prompt Maestro — Xinfer dominio** | Implementa las 7 responsabilidades autónomas de Xinfer: ReadinessState abstract record, PredictionEngine, XAI DNA 14 factores, 4 adaptadores. Ejecutar DESPUÉS del Chassis. |
| 20 | `PM-CELL-AssetManager.md` | `docs/Prompts AG/` | **Prompt Maestro — AssetManager dominio** | Implementa la Cell AssetManager: Asset aggregate, calibración, mantenimiento, retiro GxP, XinferEventConsumer. Ejecutar DESPUÉS del Chassis con [CellName]=AssetManager. |
| 21 | `PM-CELL-ColdChain.md` | `docs/Prompts AG/archive/` | **SUPERSEDIDO — archivar** | Prompt Maestro original de ColdChain. Supersedido por PM-CELL-Xinfer-v2.md. Conservar como historial. No ejecutar. |
| 22 | `PM-FIX-Xinfer-Outbox-Health.md` | `docs/Prompts AG/` | **Prompt Maestro — fix ejecutado** | Fix de 2 gaps detectados por auditoría C3: Outbox Pattern + /health/operational endpoint. YA EJECUTADO. Conservar como referencia para PM-CELL-CHASSIS.md. |
| 23 | `PM-RENAME-ColdChain-to-Xinfer.md` | `docs/Prompts AG/` | **Prompt Maestro — rename ejecutado** | Rename de AHS.Cell.ColdChain → AHS.Cell.Xinfer. YA EJECUTADO. Conservar como historial de decisión de naming. |
| 24 | `PM-RENAME-WebUI-to-Hive.md` | `docs/Prompts AG/` | **Prompt Maestro — rename ejecutado** | Rename de AHS.Web.UI → AHS.Web.Hive. YA EJECUTADO. Conservar como historial de decisión de naming. |
| 25 | `PM-DASHBOARD-ColdChain-Demo.md` | `docs/Prompts AG/` | **Prompt Maestro — dashboard demo** | Generó el dashboard demo con CSV de pharma/traceability. YA EJECUTADO. Referencia para futuros dashboards de demo. |
| 26 | `PM-FOUNDATION-AHS-Common-WebCommon.md` | `docs/Prompts AG/` | **Prompt Maestro — fundación ejecutado** | Generó AHS.Common y AHS.Web.Common (Sovereign Elite RCL). YA EJECUTADO. Referencia si se necesita regenerar la fundación. |
| 27 | `PM-ASPIRE-AppHost.md` | `docs/Prompts AG/` | **Prompt Maestro — .NET Aspire** | Genera AHS.AppHost para orquestar todos los servicios localmente. Ejecutar cuando haya 2+ Cells activas con Docker. |
| 28 | `PM-XINFER-7Cell-Architecture.md` | `docs/Prompts AG/` | **Prompt Maestro — arquitectura 7 Cells** | Variante arquitectónica de Xinfer con 7 Cells separadas. Referencia conceptual — evaluar con C1 antes de ejecutar. |
| 29 | `AHS-PRD-AND-TECHNOLOGY-RADAR.md` | `docs/00_Constitution/` | **PRDs + Technology Radar** | PRDs de Xinfer, AssetManager, FinTracker + Technology Radar (Adopt/Trial/Hold/Avoid). Referencia estratégica para C1. |
| 30 | `AHS-SKILLS-DISTRIBUTION-MAP.md` | `docs/00_Constitution/` | **Mapa de distribución de skills** | Define qué skill va en C1, C2, AG, y en qué orden. Referencia para mantener las instancias sincronizadas. |
| 31 | `DotNet10-SaaS-Core-UPDATED.md` | `.agent/skills/01_Core/` | **Skill técnico — .NET 10** | Skill de AG con patrones de .NET 10: AOT, Source Generators, HybridCache, Minimal API. Actualizado para V3.1.2. |
| 32 | `Hybrid-Persistence-Standard-UPDATED.md` | `.agent/skills/03_Backend/` | **Skill técnico — persistencia** | Skill de AG con patrones EF Core + Dapper: write/read split, Outbox, TenantSessionInterceptor. Actualizado para V3.1.2. |

---

## RESUMEN POR DESTINO

| Destino | Archivos | Propósito |
|---|---|---|
| `docs/00_Constitution/` | 1, 2, 4, 5, 6, 7, 29, 30 | Leyes del ecosistema — referencia permanente |
| `docs/00_Constitution/archive/` | 3, 17 | Versiones anteriores — historial |
| `src/Cells/Xinfer/docs/` | 8, 9, 10 | Documentación específica de la Cell Xinfer |
| `docs/Prompts AG/` | 18, 19, 20, 22, 23, 24, 25, 26, 27, 28 | Prompt Maestros para AG |
| `docs/Prompts AG/archive/` | 21 | PMs supersedidos |
| **Google AI Studio C1** | 11 | Pegar en System Instructions |
| **Google AI Studio C2** | 12 | Pegar en System Instructions |
| **Pegar en chat (sesión)** | 13, 14, 15, 16 | Contexto por sesión — NO en System Instructions |
| `.agent/skills/01_Core/` | 31 | Skill de AG — .NET 10 |
| `.agent/skills/03_Backend/` | 32 | Skill de AG — persistencia |

---

## SKILLS (.skill) — 9 archivos adicionales

| Archivo | Destino | Uso |
|---|---|---|
| `ahs-cellular-architecture.skill` | `.agent/skills/02_Architecture/` | Arquitectura Cell-Based para AG |
| `ahs-dotnet-architect-UPDATED.skill` | `.agent/skills/02_Architecture/` | Patrones .NET architect actualizados |
| `ahs-product-cell-canvas.skill` | `.agent/skills/06_Product/` | Cell Canvas y PRD template |
| `cell-integration-patterns.skill` | `.agent/skills/02_Architecture/` | Patrones inter-Cell (Service Bus, Outbox) |
| `cqrs-clean-architecture-patterns.skill` | `.agent/skills/02_Architecture/` | CQRS + Clean Architecture |
| `ddd-strategic-design.skill` | `.agent/skills/02_Architecture/` | DDD estratégico |
| `multi-agent-brainstorming.skill` | `.agent/skills/05_Workflow/` | Panel multi-agente |
| `prompt-engineering-ag.skill` | `.agent/skills/05_Workflow/` | Prompt Engineering para AG |
| `regulatory-compliance-matrix.skill` | `.agent/skills/01_Core/` | FDA, GDPR, HACCP, ISO 27001 |

---

## REGLA DE ORO

```
Si el documento dice QUIÉN PUEDE HACER QUÉ    → 00_Constitution/
Si el documento dice QUÉ CÉLULAS EXISTEN      → AHS-CELL-CATALOG.md
Si el documento dice QUÉ HACE UNA CELL        → src/Cells/[Name]/docs/
Si el documento dice CÓMO CONSTRUIR UNA CELL  → docs/Prompts AG/
Si el documento es PARA C1 O C2               → pegar en chat, no en System Instructions
```