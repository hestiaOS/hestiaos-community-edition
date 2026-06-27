# HestiaOS Community Edition — Windows Configuration Template

> Konfigurationsvorlage für den Betrieb der Community Edition unter Windows 11.

## 1. Umgebungsvariablen

Erstelle eine Datei `.env` im `hestiaos-community-edition/` Verzeichnis:

```env
# ── Core ──────────────────────────────────────────────────────────────────
CORE_HOST=127.0.0.1
CORE_PORT=8000
CORE_LOG_LEVEL=info

# ── MCP Server ────────────────────────────────────────────────────────────
MCP_HOST=127.0.0.1
MCP_PORT=8001
MCP_LOG_LEVEL=info

# ── Edition ────────────────────────────────────────────────────────────────
HESTIAOS_EDITION=community
HESTIAOS_ENV=development

# ── Pfade (Windows) ───────────────────────────────────────────────────────
# Passe diese Pfade an deine Installation an
HESTIAOS_ROOT=C:\Users\%USERNAME%\hestiaos
HESTIAOS_SDK=%HESTIAOS_ROOT%\sdk
HESTIAOS_CORE=%HESTIAOS_ROOT%\hestiaos-core
HESTIAOS_MCP=%HESTIAOS_ROOT%\mcp-server
```

## 2. PowerShell-Profil

Füge folgendes zu deinem PowerShell-Profil hinzu (`$PROFILE`):

```powershell
# HestiaOS Community Edition — Aliase
function hestiaos-start-core {
    & "$env:USERPROFILE\hestiaos\hestiaos-community-edition\scripts\start-core.ps1"
}
function hestiaos-stop-core {
    & "$env:USERPROFILE\hestiaos\hestiaos-community-edition\scripts\start-core.ps1" -Stop
}
function hestiaos-health {
    curl.exe -s http://127.0.0.1:8000/health
}

Set-Alias -Name hcore -Value hestiaos-start-core
Set-Alias -Name hstop -Value hestiaos-stop-core
Set-Alias -Name hcheck -Value hestiaos-health
```

## 3. Windows-Firewall

Falls Core von anderen Geräten im Netzwerk erreichbar sein soll:

```powershell
# PowerShell als Administrator
New-NetFirewallRule -DisplayName "HestiaOS Core" `
    -Direction Inbound `
    -LocalPort 8000 `
    -Protocol TCP `
    -Action Allow
```

> **Hinweis:** Für lokale Entwicklung nicht nötig — Core bindet an `127.0.0.1`.

## 4. VS Code Settings

Erstelle `.vscode/settings.json` im `hestiaos-community-edition/` Verzeichnis:

```json
{
    "python.defaultInterpreterPath": "python3",
    "python.terminal.activateEnvironment": false,
    "files.watcherExclude": {
        "**/.git/**": true,
        "**/__pycache__/**": true,
        "**/node_modules/**": true
    },
    "terminal.integrated.env.windows": {
        "HESTIAOS_EDITION": "community",
        "HESTIAOS_ENV": "development"
    }
}
```

## 5. Docker Desktop (optional)

Falls Docker Desktop verwendet wird, stelle sicher:

1. Docker Desktop → Settings → Resources → WSL Integration → Ubuntu-24.04 aktivieren
2. `docker compose up -d` im `hestiaos-community-edition/` Verzeichnis ausführen

## 6. Python Virtual Environment (empfohlen)

```powershell
# Einmalig
cd $env:USERPROFILE\hestiaos\hestiaos-community-edition
python -m venv .venv

# Aktivieren (jedes Terminal)
.\.venv\Scripts\Activate.ps1

# Dependencies installieren
pip install -r requirements-community.txt
```
