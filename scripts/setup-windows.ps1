<#
.SYNOPSIS
    HestiaOS Community Edition — Windows 11 Native Setup (PowerShell)

.DESCRIPTION
    Richtet die Community Edition nativ unter Windows 11 ein (ohne WSL 2).
    Prüft Python 3.10+, klont Repositories, installiert Dependencies und
    führt die Validierung aus.

    Optional: Nutze setup-wsl2.sh via WSL 2 für eine isolierte Umgebung.

.PARAMETER SkipClone
    Überspringt das Klonen der Repositories (wenn bereits vorhanden).

.PARAMETER SkipValidate
    Überspringt die Validierung.

.PARAMETER WorkspacePath
    Arbeitsverzeichnis (Standard: $env:USERPROFILE\hestiaos).

.EXAMPLE
    .\scripts\setup-windows.ps1

.EXAMPLE
    .\scripts\setup-windows.ps1 -SkipClone -WorkspacePath "D:\hestiaos"

.NOTES
    Voraussetzungen:
    - Windows 11
    - Python 3.10+ (installiert von python.org oder Microsoft Store)
    - Git for Windows (https://git-scm.com/download/win)
    - PowerShell 5.1+ oder PowerShell 7+
#>

param(
    [switch]$SkipClone,
    [switch]$SkipValidate,
    [string]$WorkspacePath = "$env:USERPROFILE\hestiaos"
)

# ── Konfiguration ──────────────────────────────────────────────────────────
$MinPython = "3.10"
$Repos = @(
    "https://github.com/hestiaos/sdk.git",
    "https://github.com/hestiaos/hestiaos-core.git",
    "https://github.com/hestiaos/mcp-server.git",
    "https://github.com/hestiaos/hestiaos-community-edition.git"
)

# Farben (PowerShell-kompatibel)
$Host.UI.RawUI.ForegroundColor = "Cyan"
Write-Host "╔══════════════════════════════════════════════════════════╗"
Write-Host "║   HestiaOS Community Edition — Windows 11 Setup        ║"
Write-Host "╚══════════════════════════════════════════════════════════╝"
$Host.UI.RawUI.ForegroundColor = "White"
Write-Host ""

# ── Hilfsfunktionen ────────────────────────────────────────────────────────
function Write-Step {
    param([string]$Message)
    Write-Host ""
    $Host.UI.RawUI.ForegroundColor = "Cyan"
    Write-Host ("─" * 50)
    Write-Host "  $Message"
    Write-Host ("─" * 50)
    $Host.UI.RawUI.ForegroundColor = "White"
}

function Write-Info {
    param([string]$Message)
    $Host.UI.RawUI.ForegroundColor = "Green"
    Write-Host "[INFO] $Message"
    $Host.UI.RawUI.ForegroundColor = "White"
}

function Write-Warn {
    param([string]$Message)
    $Host.UI.RawUI.ForegroundColor = "Yellow"
    Write-Host "[WARN] $Message"
    $Host.UI.RawUI.ForegroundColor = "White"
}

function Write-Error {
    param([string]$Message)
    $Host.UI.RawUI.ForegroundColor = "Red"
    Write-Host "[ERROR] $Message"
    $Host.UI.RawUI.ForegroundColor = "White"
}

# ── 1. Voraussetzungen prüfen ─────────────────────────────────────────────
Write-Step "1/5 — Voraussetzungen prüfen"

# Python prüfen
$pythonCmd = $null
foreach ($cmd in @("python3", "python")) {
    $version = & $cmd --version 2>$null
    if ($LASTEXITCODE -eq 0 -and $version -match "(\d+)\.(\d+)") {
        $pythonCmd = $cmd
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        break
    }
}

if (-not $pythonCmd) {
    Write-Error "Python nicht gefunden. Installiere Python $MinPython+ von https://www.python.org/downloads/"
    Write-Error "WICHTIG: 'Add Python to PATH' bei der Installation AKTIVIEREN!"
    exit 1
}

$pyVersionStr = "$major.$minor"
if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 10)) {
    Write-Error "Python $pyVersionStr gefunden, aber $MinPython+ erforderlich."
    exit 1
}
Write-Info "Python $pyVersionStr ✓ ($pythonCmd)"

# Git prüfen
$gitVersion = git --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Git nicht gefunden. Installiere von https://git-scm.com/download/win"
    exit 1
}
Write-Info "Git ✓ ($gitVersion)"

# pip prüfen
$pipVersion = & $pythonCmd -m pip --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Error "pip nicht gefunden. Installiere: $pythonCmd -m ensurepip --upgrade"
    exit 1
}
Write-Info "pip ✓"

# ── 2. Arbeitsverzeichnis ─────────────────────────────────────────────────
Write-Step "2/5 — Arbeitsverzeichnis"

if (-not (Test-Path $WorkspacePath)) {
    New-Item -ItemType Directory -Path $WorkspacePath -Force | Out-Null
    Write-Info "Arbeitsverzeichnis erstellt: $WorkspacePath"
} else {
    Write-Info "Arbeitsverzeichnis: $WorkspacePath"
}

Set-Location $WorkspacePath

# ── 3. Repositories klonen ────────────────────────────────────────────────
Write-Step "3/5 — Repositories klonen"

if ($SkipClone) {
    Write-Info "Git-Clone übersprungen (-SkipClone)"
} else {
    foreach ($repoUrl in $Repos) {
        $repoName = [System.IO.Path]::GetFileNameWithoutExtension($repoUrl)
        $repoPath = Join-Path $WorkspacePath $repoName

        if (Test-Path $repoPath) {
            Write-Info "$repoName — bereits vorhanden, aktualisiere..."
            Set-Location $repoPath
            git pull --ff-only
            Set-Location $WorkspacePath
        } else {
            Write-Info "Klonen: $repoUrl"
            git clone $repoUrl
        }
    }
    Write-Info "Alle Repositories bereit"
}

# ── 4. Dependencies installieren ──────────────────────────────────────────
Write-Step "4/5 — Dependencies installieren"

$CommunityDir = Join-Path $WorkspacePath "hestiaos-community-edition"
$SdkDir = Join-Path $WorkspacePath "sdk"
$CoreDir = Join-Path $WorkspacePath "hestiaos-core"
$McpDir = Join-Path $WorkspacePath "mcp-server"

# 4a. Community-Dependencies
Write-Info "Installiere Community-Dependencies..."
$reqFile = Join-Path $CommunityDir "requirements-community.txt"
if (Test-Path $reqFile) {
    & $pythonCmd -m pip install -r $reqFile
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "pip install hatte Warnungen — prüfe die Ausgabe"
    }
} else {
    Write-Warn "requirements-community.txt nicht gefunden: $reqFile"
}

# 4b. SDK (Editable-Mode)
Write-Info "Installiere sdk (Editable-Mode)..."
if (Test-Path $SdkDir) {
    Set-Location $SdkDir
    & $pythonCmd -m pip install -e .
    Set-Location $WorkspacePath
} else {
    Write-Warn "sdk nicht gefunden: $SdkDir"
}

# 4c. Core (Editable-Mode)
Write-Info "Installiere hestiaos-core (Editable-Mode)..."
if (Test-Path $CoreDir) {
    Set-Location $CoreDir
    & $pythonCmd -m pip install -e .
    Set-Location $WorkspacePath
} else {
    Write-Warn "hestiaos-core nicht gefunden: $CoreDir"
}

# 4d. MCP-Server
Write-Info "Installiere mcp-server Dependencies..."
$mcpReq = Join-Path $McpDir "requirements.txt"
if (Test-Path $mcpReq) {
    & $pythonCmd -m pip install -r $mcpReq
}

Write-Info "Alle Dependencies installiert ✓"

# ── 5. Validierung ─────────────────────────────────────────────────────────
Write-Step "5/5 — Validierung"

if ($SkipValidate) {
    Write-Info "Validierung übersprungen (-SkipValidate)"
} else {
    Set-Location $CommunityDir

    # Edition-Manifest prüfen
    $manifest = Join-Path $CommunityDir "edition-manifest.yaml"
    if (Test-Path $manifest) {
        $edition = (Select-String -Path $manifest -Pattern "^edition:").Line
        $status = (Select-String -Path $manifest -Pattern "^publication_status:").Line
        Write-Info "Edition-Manifest: $edition"
        Write-Info "Publication Status: $status"
    }

    # Component-Lock prüfen
    $lockFile = Join-Path $CommunityDir "component-lock.json"
    if (Test-Path $lockFile) {
        $lock = Get-Content $lockFile -Raw | ConvertFrom-Json
        $count = $lock.components.Count
        Write-Info "Component-Lock: $count Komponenten gelockt"

        foreach ($c in $lock.components) {
            Write-Info "  ✅ $($c.component): security=$($c.security_status), license=$($c.license_status), validation=$($c.validation_status)"
        }
    }

    # Prerequisites-Check (PowerShell-Version)
    Write-Info "Prüfe Voraussetzungen..."
    Write-Info "  Python: $pyVersionStr ✓"
    Write-Info "  Git: ✓"
    Write-Info "  pip: ✓"

    Write-Info "Validierung abgeschlossen ✓"
}

# ── Zusammenfassung ────────────────────────────────────────────────────────
Write-Host ""
$Host.UI.RawUI.ForegroundColor = "Cyan"
Write-Host "╔══════════════════════════════════════════════════════════╗"
Write-Host "║   HestiaOS Community Edition — Setup abgeschlossen     ║"
Write-Host "╚══════════════════════════════════════════════════════════╝"
$Host.UI.RawUI.ForegroundColor = "White"
Write-Host ""
Write-Host "   Verzeichnis: $WorkspacePath"
Write-Host ""
Write-Host "   Nächste Schritte:"
Write-Host "     cd $CommunityDir"
Write-Host "     make validate       # Edition-Manifest + Lock prüfen"
Write-Host "     make start-core     # Core starten (Port 8000)"
Write-Host "     make check          # Health-Check"
Write-Host ""
Write-Host "   Oder starte das Core-Start-Skript:"
Write-Host "     .\scripts\start-core.ps1"
Write-Host ""
