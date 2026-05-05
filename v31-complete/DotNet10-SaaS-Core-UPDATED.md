# Skill: .NET 10 SaaS Core Development
# ID: AHS-DOTNET10-CORE
# Version: 3.1 — Updated for Blueprint V3.1 (Cellular Architecture)

## Context

Coding standards for the AHS Ecosystem using .NET 10, C# 14, and Native AOT.
Optimized for the Cellular Architecture where each Cell follows
`AHS.Cell.[Name].[Layer]` namespace convention.

---

## Project Structure (V3.1 Canonical)

```
AHS.Cell.[CellName]/
├── AHS.Cell.[CellName].Domain/          ← Zero dependencies. Pure domain.
├── AHS.Cell.[CellName].Application/     ← CQRS handlers. Depends on Domain only.
├── AHS.Cell.[CellName].Infrastructure/  ← EF Core, Dapper, Service Bus, Redis.
├── AHS.Cell.[CellName].Contracts/       ← Public ICellEvent records. No dependencies.
├── AHS.Cell.[CellName].API/             ← Minimal API, Native AOT, JsonSerializerContext.
└── AHS.Cell.[CellName].Tests/           ← xUnit, Testcontainers, NetArchTest, Reqnroll.

AHS.Common/                              ← GxP Ledger, SIMD engines (cross-cutting)
AHS.Web.Common/                          ← Sovereign Elite RCL (Blazor components)
AHS.Web.UI/                              ← Control Tower
AHS.ControlTower.BFF/                    ← BFF for real-time + analytical aggregation
```

**Solution format:** `.slnx` (VS2026). AG must use Solution Folders to group by Cell.

---

## C# 14 Features — Mandatory Usage

```csharp
// ✅ Primary Constructors — clean DI, no boilerplate
public class ShipmentCommandHandler(
    IEventStore store,
    ICellEventPublisher publisher,
    ILogger<ShipmentCommandHandler> log)
{ ... }

// ✅ field keyword — backing field inline
public string TenantSlug
{
    get;
    set => field = value?.ToLowerInvariant()
        ?? throw new ArgumentNullException(nameof(value));
}

// ✅ Generic Attributes — metadata-driven domain logic
[DomainEvent(Version = 2)]
public record ShipmentCreated_V2(...) : DomainEvent;

// ✅ static abstract members — Generic Math for FinTech precision
public interface IMonetaryValue<T> where T : IMonetaryValue<T>
{
    static abstract T operator +(T left, T right);
    static abstract T Zero { get; }
}
```

---

## Constraints & Native AOT (non-negotiable)

### Zero Reflection Rule

```csharp
// ❌ FORBIDDEN — breaks Native AOT
Type.GetType("AHS.Cell.ColdChain.Domain.Shipment")
Activator.CreateInstance(typeof(T))
Assembly.GetExecutingAssembly().GetTypes()
typeof(T).GetMethod("Handle", BindingFlags.NonPublic)

// ✅ REQUIRED — explicit, compile-time safe
builder.Services.AddScoped<IShipmentRepository, ShipmentRepository>();
builder.Services.AddScoped<ShipmentCommandHandler>();
```

### Source Generators — Mandatory

```csharp
// JSON — every type crossing the API boundary
[JsonSerializable(typeof(ShipmentDto))]
[JsonSerializable(typeof(List<ShipmentSummaryDto>))]
[JsonSerializable(typeof(CreateShipmentRequest))]
[JsonSourceGenerationOptions(
    PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase,
    WriteIndented = false)]
public partial class CellNameJsonContext : JsonSerializerContext { }

// Logging — Source Generated (no reflection at runtime)
public static partial class Log
{
    [LoggerMessage(Level = LogLevel.Information,
        Message = "Shipment {ShipmentId} sealed by {Actor}")]
    public static partial void ShipmentSealed(
        this ILogger logger, Guid shipmentId, string actor);
}
```

### CQRS — No MediatR

```csharp
// ❌ FORBIDDEN — MediatR uses reflection, breaks AOT
services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly()));

// ✅ REQUIRED — explicit handler registration, AOT-safe
// Inject handlers directly in Minimal API endpoints:
app.MapPost("/api/shipments", async (
    CreateShipmentRequest req,
    RegisterShipmentHandler handler,   // ← direct injection
    ITenantContext tenant,
    CancellationToken ct) => { ... });

// Or use explicit dispatch table (switch expression — no reflection):
// See cqrs-clean-architecture-patterns skill for full pattern
```

---

## Core Technical Requirements

### High Performance — Hot Path Rules

```csharp
// P99 targets: Oracle < 10ms, Sensor ingestion < 50ms
// Rules for hot paths (Oracle, SIMD thermal engines, sensor pipeline):

// ✅ ValueTask — no heap allocation on cache hit
public async ValueTask<OracleResult> CalculateAsync(OracleRequest req, CancellationToken ct)

// ✅ Span<T> + stackalloc — no heap allocation for ≤256 elements
Span<double> buffer = stackalloc double[256];

// ✅ readonly record struct — stack allocated data transfer
public readonly record struct ThermalDataPoint(
    double CelsiusValue, DateTimeOffset Timestamp, string ZoneId);

// ❌ FORBIDDEN in hot paths
readings.Where(r => r > 0).Select(r => r * 1.8).Sum()  // 3 allocations
$"sensor_{id}_zone_{zoneId}"                             // heap allocation
new List<double>(readings)                               // heap allocation
```

### Financial Calculations — Generic Math

```csharp
// For FinTracker Cell — precision arithmetic
public readonly record struct Money(decimal Amount, string Currency)
    : IMonetaryValue<Money>
{
    public static Money operator +(Money left, Money right)
    {
        if (left.Currency != right.Currency)
            throw new CurrencyMismatchException(left.Currency, right.Currency);
        return new Money(left.Amount + right.Amount, left.Currency);
    }
    public static Money Zero => new(0m, "EUR");
}
```

### Minimal API — Mandatory for Cell endpoints

```csharp
// Program.cs — AOT-optimized host
var builder = WebApplication.CreateSlimBuilder(args);

// ❌ NEVER — full WebApplication.CreateBuilder adds unnecessary middleware
// ✅ ALWAYS — CreateSlimBuilder for Cell APIs

// Endpoint registration pattern
app.MapGroup("/api/shipments")
    .MapShipmentEndpoints()
    .RequireAuthorization("SameTenant");

// Extension method (keeps Program.cs clean)
public static RouteGroupBuilder MapShipmentEndpoints(this RouteGroupBuilder group)
{
    group.MapPost("/", CreateShipment);
    group.MapGet("/{id:guid}", GetShipmentById);
    group.MapPost("/{id:guid}/seal", SealShipment);
    return group;
}
```

### Purity Rule — No Logic in API Layer

```csharp
// ❌ FORBIDDEN — business logic in endpoint
app.MapPost("/api/shipments", async (CreateShipmentRequest req, AppDbContext db) =>
{
    if (req.Temperature < -80) return Results.BadRequest("Too cold");  // ← domain logic here
    var shipment = new Shipment { ... };
    db.Add(shipment);
    await db.SaveChangesAsync();
    return Results.Created(...);
});

// ✅ REQUIRED — endpoint delegates to handler, handler delegates to domain
app.MapPost("/api/shipments", async (
    CreateShipmentRequest req,
    RegisterShipmentHandler handler,
    ITenantContext tenant,
    ClaimsPrincipal user,
    CancellationToken ct) =>
{
    var cmd = new RegisterShipmentCommand(
        req.CargoType, req.Origin, req.Destination,
        tenant.TenantId, user.GetUserId(), user.GetDisplayName(),
        req.ReasonForChange);  // ← GxP: always required
    var id = await handler.HandleAsync(cmd, ct);
    return Results.Created($"/api/shipments/{id}", new { id });
});
```

---

## AOT Analyzer — CI Gate (mandatory)

```yaml
# In GitHub Actions — must pass before Docker build
- name: AOT trim analysis
  run: |
    dotnet build AHS.Cell.[Name].API \
      /p:PublishAot=true \
      /p:EnableTrimAnalyzer=true \
      /warnaserror:IL2026,IL2067,IL3050
```

```xml
<!-- Every Cell API .csproj -->
<PropertyGroup>
  <PublishAot>true</PublishAot>
  <RuntimeIdentifier>linux-x64</RuntimeIdentifier>
  <StripSymbols>true</StripSymbols>
  <InvariantGlobalization>true</InvariantGlobalization>
  <OptimizationPreference>Size</OptimizationPreference>
</PropertyGroup>
```

---

## Changes from V2.0

| V2.0 | V3.1 |
|---|---|
| `src/suites/` hierarchy | `AHS.Cell.[Name].[Layer]` per Cell |
| `src/shared-kernel/` | `AHS.Common/` (cross-cutting) + `AHS.Cell.[Name].Contracts/` (inter-cell) |
| `src/common-application/` with MediatR behaviors | Application layer per Cell — no MediatR |
| `src/platform/` | `AHS.Common/` + `AHS.ControlTower.BFF/` |
| MediatR for CQRS dispatch | Explicit handlers, direct injection |
| "Shared Kernel" concept | `AHS.Common/` for shared infrastructure, `Contracts/` for public events |
| `.slnx` with shared-kernel Solution Folder | `.slnx` with one Solution Folder per Cell |
