# HestiaOS Community Edition — Windows 11 Deployment Guide

> Vollständige Anleitung für die Installation und den Betrieb der Community Edition
> unter Windows 11 — sowohl via WSL 2 (empfohlen) als auch nativ.

---

## 1. Übersicht

Die Community Edition besteht aus 3 Komponenten:

| Komponente | Beschreibung | Port |
|---|---|---|
| **hestiaos-core** | Governance Kernel & Execution Runtime (FastAPI) | `:8000` |
| **mcp-server** | MCP Server (STDIO/HTTP) | `:8001` |
| **sdk** | Public SDK (Python-Bibliothek) | — |

**Deployment-Optionen:**

| Option | Beschreibung | Empfohlen für |
|---|---|---|
| **A: WSL 2** | Ubuntu 24.04 via WSL 2 | Entwicklung, Isolation |
| **B: Windows nativ** | Python direkt auf Windows | Schnelle Tests, einfache Setup |
| **C: Docker Desktop** | Container via docker-compose | CI/CD, reproduzierbare Builds |

---

## 2. Option A: WSL 2 (empfohlen)

### 2.1 Voraussetzungen

- Windows 11 (Build 22000+)
- Administrator-Rechte (für WSL 2 Installation)

### 2.2 WSL 2 installieren

PowerShell **als Administrator** ausführen:

```powershell
# WSL 2 aktivieren + Ubuntu 24.04 installieren
wsl --install -d Ubuntu-24.04

# Neustart erforderlich
Restart-Computer
```

Nach dem Neustart:

```powershell
# WSL 2 als Standard setzen
wsl --set-default-version 2

# Ubuntu starten (erstellt Benutzerkonto)
wsl -d Ubuntu-24.04
```

### 2.3 Python + Tools in WSL 2

```bash
# In der WSL 2 Ubuntu Shell:
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv git make curl
python3 --version  # Sollte 3.10+ sein
```

### 2.4 Community Edition installieren

```bash
# Setup-Skript ausführen (automatisch: klonen, installieren, validieren)
cd ~
git clone https://github.com/hestiaos/hestiaos-community-edition.git
cd hestiaos-community-edition
bash scripts/setup-wsl2.sh
```

Oder Schritt für Schritt:

```bash
# Repositories klonen
mkdir -p ~/hestiaos && cd ~/hestiaos
git clone https://github.com/hestiaos/sdk.git
git clone https://github.com/hestiaos/hestiaos-core.git
git clone https://github.com/hestiaos/mcp-server.git
git clone https://github.com/hestiaos/hestiaos-community-edition.git

# Dependencies installieren
cd ~/hestiaos/hestiaos-community-edition
pip install -r requirements-community.txt

# SDK + Core im Editable-Mode
cd ~/hestiaos/sdk && pip install -e .
cd ~/hestiaos/hestiaos-core && pip install -e .

# Validieren
cd ~/hestiaos/hestiaos-community-edition
make validate
```

### 2.5 Core starten

```bash
cd ~/hestiaos/hestiaos-community-edition
make start-core
# → http://127.0.0.1:8000
```

### 2.6 Von Windows aus zugreifen

WSL 2 teilt sich das Netzwerk mit Windows. Core ist erreichbar unter:

```
http://localhost:8000
```

---

## 3. Option B: Windows 11 nativ

### 3.1 Voraussetzungen

- Windows 11
- Python 3.10+ von [python.org](https://www.python.org/downloads/)
  - **WICHTIG:** "Add Python to PATH" bei Installation AKTIVIEREN
- Git for Windows von [git-scm.com](https://git-scm.com/download/win)

### 3.2 PowerShell Setup

PowerShell **als Administrator** öffnen:

```powershell
# Setup-Skript ausführen
.\scripts\setup-windows.ps1
```

Oder Schritt für Schritt:

```powershell
# Python-Version prüfen
python --version  # Sollte 3.10+

# Repositories klonen
mkdir $env:USERPROFILE\hestiaos
cd $env:USERPROFILE\hestiaos
git clone https://github.com/hestiaos/sdk.git
git clone https://github.com/hestiaos/hestiaos-core.git
git clone https://github.com/hestiaos/mcp-server.git
git clone https://github.com/hestiaos/hestiaos-community-edition.git

# Dependencies installieren
cd $env:USERPROFILE\hestiaos\hestiaos-community-edition
pip install -r requirements-community.txt

# SDK + Core im Editable-Mode
cd $env:USERPROFILE\hestiaos\sdk && pip install -e .
cd $env:USERPROFILE\hestiaos\hestiaos-core && pip install -e .
```

### 3.3 Core starten (Windows)

```powershell
# Core im Vordergrund (mit Logs)
.\scripts\start-core.ps1

# Oder im Hintergrund
.\scripts\start-core.ps1 -NoWait

# Health-Check
curl http://127.0.0.1:8000/health

# Stoppen
.\scripts\start-core.ps1 -Stop
```

---

## 4. Option C: Docker Desktop

### 4.1 Voraussetzungen

- Docker Desktop für Windows ([docker.com](https://www.docker.com/products/docker-desktop/))
- WSL 2 Backend (in Docker Desktop Einstellungen aktivieren)

### 4.2 Starten

```powershell
cd $env:USERPROFILE\hestiaos\hestiaos-community-edition
docker compose up -d

# Logs anzeigen
docker compose logs -f

# Stoppen
docker compose down
```

---

## 5. Validierung

Nach der Installation:

```bash
# Prerequisites prüfen
bash scripts/check-prerequisites.sh

# Edition-Manifest + Component-Lock validieren
make validate

# Health-Check
make check
```

Erwartete Ausgabe:

```
✅ Edition-Manifest: community
✅ Component-Lock: 3 Komponenten gelockt
   ✅ hestiaos-core: security=clean, license=cleared, validation=validated
   ✅ mcp-server: security=clean, license=cleared, validation=validated
   ✅ sdk: security=clean, license=cleared, validation=validated
✅ Core antwortet auf http://127.0.0.1:8000/health
```

---

## 6. Nächste Schritte

| Thema | Dokumentation |
|---|---|
| Quickstart (5 Minuten) | [`quickstart.md`](quickstart.md) |
| Komponenten-Start-Reihenfolge | [`component-startup-order.md`](component-startup-order.md) |
| Windows-Konfiguration | [`config-template-windows.md`](config-template-windows.md) |
| Bekannte Probleme | [`troubleshooting.md`](troubleshooting.md) |
| Build-Pipeline | [`../Makefile`](../Makefile) |
| Docker Deployment | [`../docker-compose.yml`](../docker-compose.yml) |

---

## 7. Fehlerbehebung

Siehe [`troubleshooting.md`](troubleshooting.md) für bekannte Probleme und Lösungen.
