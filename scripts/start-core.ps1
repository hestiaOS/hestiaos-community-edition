<#
.SYNOPSIS
    HestiaOS Community Edition — Core & MCP-Server Start (PowerShell)

.DESCRIPTION
    Startet den hestiaos-core (FastAPI) und optional den mcp-server.
    Führt Health-Checks durch und zeigt Logs an.

.PARAMETER CorePort
    Port für den Core-Server (Standard: 8000).

.PARAMETER CoreHost
    Host für den Core-Server (Standard: 127.0.0.1).

.PARAMETER StartMcp
    Schalter: Startet auch den MCP-Server.

.PARAMETER NoWait
    Schalter: Startet Core im Hintergrund und gibt sofort zurück.

.PARAMETER Stop
    Schalter: Stoppt laufende Core/MCP-Prozesse.

.EXAMPLE
    .\scripts\start-core.ps1
    Startet Core auf Port 8000, zeigt Logs an.

.EXAMPLE
    .\scripts\start-core.ps1 -CorePort 8080 -StartMcp
    Startet Core auf Port 8080 + MCP-Server.

.EXAMPLE
    .\scripts\start-core.ps1 -Stop
    Stoppt alle laufenden Core/MCP-Prozesse.

.NOTES
    Voraussetzungen:
    - Python 3.10+
    - Dependencies installiert (via setup-windows.ps1 oder make install)
    - hestiaos-core und mcp-server müssen geklont sein
#>

param(
    [int]$CorePort = 8000,
    [string]$CoreHost = "127.0.0.1",
    [switch]$StartMcp,
    [switch]$NoWait,
    [switch]$Stop
)

$Host.UI.RawUI.ForegroundColor = "Cyan"
Write-Host "╔══════════════════════════════════════════════════════════╗"
Write-Host "║   HestiaOS Community Edition — Core Starter            ║"
Write-Host "╚══════════════════════════════════════════════════════════╝"
$Host.UI.RawUI.ForegroundColor = "White"
Write-Host ""

# ── Skript-Pfad ermitteln ─────────────────────────────────────────────────
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommunityDir = Split-Path -Parent $ScriptDir
$WorkspacePath = Split-Path -Parent $CommunityDir
$CoreDir = Join-Path $WorkspacePath "hestiaos-core"
$McpDir = Join-Path $WorkspacePath "mcp-server"

# ── STOP-Modus ─────────────────────────────────────────────────────────────
if ($Stop) {
    Write-Host "Stoppe laufende Prozesse..."

    # Core-Prozesse beenden
    $coreProcs = Get-Process -Name "python*" -ErrorAction SilentlyContinue | `
        Where-Object { $_.CommandLine -match "uvicorn.*core\.main" -or $_.CommandLine -match "core\.main" }

    foreach ($proc in $coreProcs) {
        Write-Host "  Stoppe Core (PID: $($proc.Id))..."
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }

    # MCP-Prozesse beenden
    $mcpProcs = Get-Process -Name "python*" -ErrorAction SilentlyContinue | `
        Where-Object { $_.CommandLine -match "wiki_mcp_server" }

    foreach ($proc in $mcpProcs) {
        Write-Host "  Stoppe MCP-Server (PID: $($proc.Id))..."
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }

    # Port-Freigabe prüfen
    $portCheck = netstat -ano | Select-String ":$CorePort"
    if ($portCheck) {
        Write-Warn "Port $CorePort ist noch belegt. Warte auf Freigabe..."
        Start-Sleep -Seconds 2
    }

    Write-Host "✅ Alle Prozesse gestoppt"
    exit 0
}

# ── Voraussetzungen prüfen ─────────────────────────────────────────────────
if (-not (Test-Path $CoreDir)) {
    Write-Error "hestiaos-core nicht gefunden: $CoreDir"
    Write-Error "Klone zuerst die Repositories: .\scripts\setup-windows.ps1"
    exit 1
}

# Python finden
$pythonCmd = $null
foreach ($cmd in @("python3", "python")) {
    $version = & $cmd --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $pythonCmd = $cmd
        break
    }
}

if (-not $pythonCmd) {
    Write-Error "Python nicht gefunden. Installiere Python 3.10+ von https://www.python.org/downloads/"
    exit 1
}

# Prüfen ob Port bereits belegt ist
$portInUse = netstat -ano | Select-String "LISTENING" | Select-String ":$CorePort"
if ($portInUse) {
    Write-Warn "Port $CorePort ist bereits belegt."
    $procId = ($portInUse.Line -split '\s+')[-1]
    $procName = (Get-Process -Id $procId -ErrorAction SilentlyContinue).ProcessName
    Write-Warn "  Belegt von: $procName (PID: $procId)"
    Write-Warn "  Verwende -Stop zuerst oder -CorePort <anderer_port>"
    exit 1
}

# ── Core starten ───────────────────────────────────────────────────────────
Write-Host "🚀 Starte hestiaos-core auf $CoreHost`:$CorePort ..."
Write-Host ""

Set-Location $CoreDir

if ($NoWait) {
    # Hintergrundstart
    $jobName = "HestiaOS-Core"
    $job = Start-Job -Name $jobName -ScriptBlock {
        param($cmd, $dir, $hostAddr, $port)
        Set-Location $dir
        & $cmd -m uvicorn core.main:app --host $hostAddr --port $port --log-level info
    } -ArgumentList $pythonCmd, $CoreDir, $CoreHost, $CorePort

    Write-Host "✅ Core gestartet (Job: $jobName)"
    Write-Host "   Logs anzeigen: Receive-Job -Name $jobName"
    Write-Host "   Stoppen:       .\scripts\start-core.ps1 -Stop"

    # Kurz warten und Health-Check
    Start-Sleep -Seconds 3
} else {
    # Vordergrundstart (zeigt Logs)
    Write-Host "Drücke Ctrl+C zum Stoppen"
    Write-Host ""
    & $pythonCmd -m uvicorn core.main:app --host $CoreHost --port $CorePort --reload --log-level info
    exit $LASTEXITCODE
}

# ── Health-Check ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "🔍 Health-Check..."

try {
    $response = Invoke-WebRequest -Uri "http://${CoreHost}:${CorePort}/health" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "  ✅ Core antwortet: HTTP $($response.StatusCode)"
} catch {
    Write-Warn "  ⚠️  Core nicht erreichbar (möglicherweise noch am Starten)"
    Write-Warn "  Prüfe später: curl http://${CoreHost}:${CorePort}/health"
}

# ── MCP-Server starten (optional) ──────────────────────────────────────────
if ($StartMcp) {
    Write-Host ""
    Write-Host "🚀 Starte mcp-server..."

    if (-not (Test-Path $McpDir)) {
        Write-Warn "mcp-server nicht gefunden: $McpDir — überspringe"
    } else {
        $mcpJobName = "HestiaOS-MCP"
        $mcpJob = Start-Job -Name $mcpJobName -ScriptBlock {
            param($cmd, $dir)
            Set-Location $dir
            & $cmd wiki_mcp_server.py
        } -ArgumentList $pythonCmd, $McpDir

        Write-Host "  ✅ MCP-Server gestartet (Job: $mcpJobName)"
        Start-Sleep -Seconds 2

        # MCP-Health-Check
        $mcpRunning = Get-Job -Name $mcpJobName -ErrorAction SilentlyContinue
        if ($mcpRunning -and $mcpRunning.State -eq "Running") {
            Write-Host "  ✅ MCP-Server läuft"
        } else {
            Write-Warn "  ⚠️  MCP-Server konnte nicht gestartet werden"
        }
    }
}

# ── Zusammenfassung ────────────────────────────────────────────────────────
Write-Host ""
$Host.UI.RawUI.ForegroundColor = "Cyan"
Write-Host "╔══════════════════════════════════════════════════════════╗"
Write-Host "║   HestiaOS Community Edition — Läuft                   ║"
Write-Host "╚══════════════════════════════════════════════════════════╝"
$Host.UI.RawUI.ForegroundColor = "White"
Write-Host ""
Write-Host "   Core:     http://$CoreHost`:$CorePort"
Write-Host "   Health:   http://$CoreHost`:$CorePort/health"
if ($StartMcp) {
    Write-Host "   MCP:      läuft (Port 8001)"
}
Write-Host ""
Write-Host "   Stoppen:  .\scripts\start-core.ps1 -Stop"
Write-Host ""
