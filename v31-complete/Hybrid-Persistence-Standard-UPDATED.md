# Skill: Hybrid Persistence Strategy
# ID: AHS-PERSISTENCE-STRATEGY
# Version: 3.1 — Updated for Blueprint V3.1 (Cellular Architecture)

## Objective

Enable AHS Cells to use the correct persistence technology per use case
without breaking Native AOT compatibility.

## The AHS Persistence Decision (non-negotiable — ADR-004)

```
Primary database:  PostgreSQL 17 (Npgsql 9.x)
Write ORM:         EF Core 10 with Source Generators
Read ORM:          Dapper (zero overhead, AOT-safe)
Cache L1:          IMemoryCache (in-process)
Cache L2:          Redis 7 via HybridCache (.NET 10)
Event transport:   Azure Service Bus
```

No Cell uses SQL Server, Excel, or CSV as primary storage.
File-based storage (Excel/CSV) is only valid for **data import adapters**
in the Infrastructure layer — never as a persistence backend.

---

## Implementation Rules

### 1. Abstraction — Domain Port (mandatory)

```csharp
// Every Cell defines IRepository<T> in its Domain layer
// Domain has ZERO knowledge of EF Core, Dapper, or any ORM
namespace AHS.Cell.[Name].Domain.Ports;

public interface I[Name]Repository
{
    Task AppendAsync(Guid aggregateId, IReadOnlyList<DomainEvent> events,
        int expectedVersion, CancellationToken ct);
    Task<[Aggregate]> LoadAsync(Guid aggregateId, CancellationToken ct);
}

public interface I[Name]ReadRepository
{
    Task<[Name]Dto?> GetByIdAsync(Guid id, CancellationToken ct);
    Task<IReadOnlyList<[Name]SummaryDto>> ListByTenantAsync(
        Guid tenantId, int pageSize, Guid? afterId, CancellationToken ct);
}
```

### 2. Static Provider Factory — AOT-Safe (mandatory)

```csharp
// ✅ AOT-safe: switch expression, no reflection
// Lives in Infrastructure layer — never in Domain or Application
public static class PersistenceProviderFactory
{
    public static IServiceCollection AddCellPersistence(
        this IServiceCollection services,
        IConfiguration config)
    {
        // Write side — EF Core 10
        services.AddDbContext<[Cell]DbContext>(o =>
            o.UseNpgsql(config.GetConnectionString("Default"), npgsql =>
                npgsql.EnableRetryOnFailure(3))
            .AddInterceptors<TenantSessionInterceptor>());

        // Read side — Dapper
        services.AddScoped<IDbConnectionFactory, NpgsqlConnectionFactory>();

        // GxP Ledger
        services.AddScoped<IEventStore, PostgresEventStore>();

        // HybridCache (L1 + L2)
        services.AddHybridCache();
        services.AddStackExchangeRedisCache(o =>
            o.Configuration = config["Redis:ConnectionString"]);

        return services;
    }
}

// ❌ FORBIDDEN — breaks Native AOT
// Activator.CreateInstance(Type.GetType(tenantStorageType))
// typeof(T).GetMethod("Register", BindingFlags.NonPublic)
```

### 3. In-Memory Performance — Span<T> for Import Adapters

```csharp
// For CSV/Excel data import (Infrastructure.Adapters only — NOT persistence backend)
public class CsvSensorImportAdapter
{
    public IReadOnlyList<NormalizedSensorReading> Parse(ReadOnlySpan<byte> csvData)
    {
        // ✅ Span<T> for zero-copy parsing
        // ✅ FrozenDictionary for high-speed lookup after parse
        var results = new List<NormalizedSensorReading>();
        // parse logic using MemoryMarshal, no heap allocations in hot path
        return results;
    }
}
// Result feeds into SensorEventPublisher → Service Bus → pipeline
// CSV is NEVER stored as the system of record
```

---

## ML & Data Synchronization Rules

- **Source of Truth:** PostgreSQL GxP Ledger — immutable, SHA256-sealed.
- **ML.NET input:** Query read model projections via Dapper.
  Never read raw files as ML input in production.
- **Data Integrity:** Validate domain data via `SignedCommand` validation
  in the Application layer. Use Source-Generated validators, not reflection.
- **Exception Policy:** Data integrity violations trigger a `DomainException`
  which the command handler seals in the GxP Ledger as an audit event.

---

## Constraints

| Rule | Detail |
|---|---|
| **Domain Purity** | Zero `DbContext`, `NpgsqlConnection`, or `FileStream` references in Domain layer |
| **AOT Readiness** | All registrations via explicit DI — no reflection scanning |
| **Write/Read split** | EF Core for writes (change tracking), Dapper for reads (zero overhead) |
| **Tenant isolation** | `TenantSessionInterceptor` sets `app.current_tenant_id` via `set_config` before every query |
| **Security** | All secrets (connection strings, HMAC keys) from Azure Key Vault via Managed Identity |
| **Audit** | Every state-changing operation sealed in GxP Ledger (append-only, REVOKE UPDATE/DELETE) |

---

## Changes from V2.0

| V2.0 | V3.1 |
|---|---|
| "Suites" | "Cells" (`AHS.Cell.[Name]`) |
| SQL / Excel / CSV as peer storage options | PostgreSQL only — Excel/CSV for import adapters only |
| `PredictionService` monitors file timestamps | ML.NET reads Dapper projections from PostgreSQL |
| Reference to `AHS-DOTNET10-CORE` DI patterns | See `DotNet10-SaaS-Core.md` skill |
| "Bounded Contexts" | "AHS Cells" per Blueprint V3.1 namespace |
