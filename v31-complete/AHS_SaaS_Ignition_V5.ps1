# ============================================================================
# AHS.SaaS ECOSYSTEM - MASTER IGNITION SCRIPT (V5.0 - Blueprint V3.1.2)
# Organism: AHS Hive | Cell: AHS Xinfer
# Ports: 5000 (Xinfer API) | 5120 (Hive UI)
# ============================================================================

$ErrorActionPreference = "Stop"
$ProjectRoot = Get-Location

Write-Host ""
Write-Host "  ██╗  ██╗██╗██╗   ██╗███████╗" -ForegroundColor Cyan
Write-Host "  ██║  ██║██║██║   ██║██╔════╝" -ForegroundColor Cyan
Write-Host "  ███████║██║██║   ██║█████╗  " -ForegroundColor Cyan
Write-Host "  ██╔══██║██║╚██╗ ██╔╝██╔══╝  " -ForegroundColor Cyan
Write-Host "  ██║  ██║██║ ╚████╔╝ ███████╗" -ForegroundColor Cyan
Write-Host "  ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝" -ForegroundColor Cyan
Write-Host "  Excursion Inference Engine — Blueprint V3.1.2" -ForegroundColor DarkCyan
Write-Host ""

# ── PATHS ─────────────────────────────────────────────────────────────────
# V3.1.2 paths — Xinfer (ex-ColdChain) + Hive (ex-Web.UI)
# If rename is not yet complete, fallback paths are provided below

$XinferApiProject = "src\Cells\Xinfer\AHS.Cell.Xinfer.API\AHS.Cell.Xinfer.API.csproj"
$HiveUIProject    = "src\Presentation\AHS.Web.Hive\AHS.Web.Hive.csproj"

# Fallback — pre-rename paths (comment out after rename is complete)
if (-not (Test-Path "$ProjectRoot\$XinferApiProject")) {
    Write-Host "[FALLBACK] Xinfer path not found — using pre-rename path" -ForegroundColor Yellow
    $XinferApiProject = "src\Cells\ColdChain\AHS.Cell.ColdChain.API\AHS.Cell.ColdChain.API.csproj"
}
if (-not (Test-Path "$ProjectRoot\$HiveUIProject")) {
    Write-Host "[FALLBACK] Hive path not found — using pre-rename path" -ForegroundColor Yellow
    $HiveUIProject = "src\Presentation\AHS.Web.UI\AHS.Web.UI.csproj"
}

# ── 1. FIREWALL ────────────────────────────────────────────────────────────
Write-Host "[NETWORK] Configuring Firewall rules (Ports 5000, 5120)..." -ForegroundColor Cyan
try {
    Remove-NetFirewallRule -DisplayName "AHS_Xinfer_API" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "AHS_Hive_UI"    -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "AHS_Xinfer_API" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow | Out-Null
    New-NetFirewallRule -DisplayName "AHS_Hive_UI"    -Direction Inbound -LocalPort 5120 -Protocol TCP -Action Allow | Out-Null
    Write-Host "  OK: Network lanes secured." -ForegroundColor Green
}
catch {
    Write-Host "  NOTE: Run as Administrator for Firewall rules. Skipping..." -ForegroundColor Yellow
}

# ── 2. BUILD ───────────────────────────────────────────────────────────────
# IMPORTANT: PublishAot=false for local dev (win-x64 runtime)
# AOT is enabled only in Release pipeline for linux-x64 (Azure Container Apps)

Write-Host "[BUILD] Compiling Xinfer Cell (win-x64, no AOT for dev)..." -ForegroundColor Cyan
dotnet build "$ProjectRoot\$XinferApiProject" -c Debug `
    /p:PublishAot=false `
    /p:RuntimeIdentifier=win-x64

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Xinfer build failed. Check errors above." -ForegroundColor Red
    exit 1
}
Write-Host "  OK: Xinfer Cell compiled." -ForegroundColor Green

Write-Host "[BUILD] Compiling AHS Hive UI..." -ForegroundColor Cyan
dotnet build "$ProjectRoot\$HiveUIProject" -c Debug

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Hive UI build failed. Check errors above." -ForegroundColor Red
    exit 1
}
Write-Host "  OK: AHS Hive compiled." -ForegroundColor Green

# ── 3. LAUNCH XINFER API ───────────────────────────────────────────────────
Write-Host "[LAUNCH] Starting Xinfer API on Port 5000..." -ForegroundColor Yellow
Start-Process -FilePath "dotnet" `
    -ArgumentList "run --project `"$ProjectRoot\$XinferApiProject`" --no-build -c Debug --urls http://0.0.0.0:5000" `
    -WindowStyle Normal `
    -PassThru | Out-Null

Write-Host "  OK: Xinfer API process started." -ForegroundColor Green
Start-Sleep -Seconds 3

# ── 4. LAUNCH HIVE UI ──────────────────────────────────────────────────────
Write-Host "[LAUNCH] Starting AHS Hive UI on Port 5120..." -ForegroundColor Yellow
Start-Process -FilePath "dotnet" `
    -ArgumentList "run --project `"$ProjectRoot\$HiveUIProject`" --no-build -c Debug --urls http://0.0.0.0:5120" `
    -WindowStyle Normal `
    -PassThru | Out-Null

Write-Host "  OK: AHS Hive UI process started." -ForegroundColor Green

# ── 5. HEALTH CHECK ────────────────────────────────────────────────────────
Write-Host "[HEALTH] Waiting for services to initialize..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

$ApiHealth = $false
$UiHealth  = $false

try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/health" -TimeoutSec 5 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "  OK: Xinfer API healthy (port 5000)" -ForegroundColor Green
        $ApiHealth = $true
    }
} catch {
    Write-Host "  WARN: Xinfer API not responding yet (may still be starting)" -ForegroundColor Yellow
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:5120" -TimeoutSec 5 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "  OK: AHS Hive UI healthy (port 5120)" -ForegroundColor Green
        $UiHealth = $true
    }
} catch {
    Write-Host "  WARN: Hive UI not responding yet (may still be starting)" -ForegroundColor Yellow
}

# ── 6. BROWSER ────────────────────────────────────────────────────────────
Write-Host "[READY] Opening AHS Hive..." -ForegroundColor Green
Start-Process "http://localhost:5120/xinfer/dashboard"

# ── 7. STATUS ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  AHS HIVE IGNITION COMPLETE" -ForegroundColor White
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Xinfer API:  http://localhost:5000" -ForegroundColor Cyan
Write-Host "  Hive UI:     http://localhost:5120" -ForegroundColor Cyan
Write-Host "  Dashboard:   http://localhost:5120/xinfer/dashboard" -ForegroundColor Cyan
Write-Host "  Health:      http://localhost:5000/health" -ForegroundColor Cyan
Write-Host ""
Write-Host "  API status:  $(if ($ApiHealth) { 'ONLINE' } else { 'STARTING...' })" `
    -ForegroundColor $(if ($ApiHealth) { 'Green' } else { 'Yellow' })
Write-Host "  UI status:   $(if ($UiHealth) { 'ONLINE' } else { 'STARTING...' })" `
    -ForegroundColor $(if ($UiHealth) { 'Green' } else { 'Yellow' })
Write-Host ""
Write-Host "  X = Excursion. Predict. Explain. Prevent." -ForegroundColor DarkCyan
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
