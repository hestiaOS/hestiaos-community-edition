# HestiaOS Community Edition — Troubleshooting

> Bekannte Probleme und Lösungen für die Community Edition unter Windows 11.

---

## 1. Python

### Python 3.10+ nicht gefunden

**Problem:** `python` oder `python3` wird nicht erkannt.

**Lösung:**

1. Python von [python.org](https://www.python.org/downloads/) installieren
2. **WICHTIG:** "Add Python to PATH" bei der Installation AKTIVIEREN
3. PowerShell neu starten
4. Prüfen: `python --version`

### pip nicht gefunden

**Problem:** `pip` oder `pip3` wird nicht erkannt.

**Lösung:**

```powershell
python -m ensurepip --upgrade
python -m pip install --upgrade pip
```

### Falsche Python-Version (WSL 2)

**Problem:** Ubuntu 24.04 hat Python 3.12 — das ist in Ordnung. Falls eine ältere Version:

```bash
sudo apt install python3.11 python3.11-pip python3.11-venv
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
```

---

## 2. Port-Konflikte

### Port 8000 bereits belegt

**Problem:** `make start-core` schlägt fehl mit "Address already in use".

**Lösung 1 — Anderen Port verwenden:**

```bash
make start-core CORE_PORT=8080
# Oder
CORE_PORT=8080 make start-core
```

**Lösung 2 — Prozess auf Port 8000 finden und beenden:**

```powershell
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F
```

```bash
# Linux / WSL 2
sudo lsof -i :8000
kill -9 <PID>
```

**Lösung 3 — Core-Start-Skript mit Stop:**

```powershell
.\scripts\start-core.ps1 -Stop
```

---

## 3. WSL 2

### WSL 2 nicht installiert

**Problem:** `wsl`-Befehl nicht gefunden.

**Lösung:**

```powershell
# PowerShell als Administrator
wsl --install -d Ubuntu-24.04
# Neustart erforderlich
Restart-Computer
```

### WSL 2 Netzwerk nicht erreichbar

**Problem:** Core läuft in WSL 2, aber `http://localhost:8000` ist von Windows aus nicht erreichbar.

**Lösung:**

```powershell
# WSL 2 Version prüfen
wsl -l -v
# Sollte Version 2 sein

# Falls Version 1: konvertieren
wsl --set-version Ubuntu-24.04 2
```

WSL 2 verwendet ein NAT-Netzwerk. `localhost` wird automatisch weitergeleitet. Falls nicht:

```bash
# In WSL 2: Core an 0.0.0.0 binden (nur für Tests!)
CORE_HOST=0.0.0.0 make start-core
```

### WSL 2: "Access denied" bei Git-Clone

**Problem:** Berechtigungsfehler beim Klonen in WSL 2.

**Lösung:**

```bash
# Repository manuell klonen
git clone https://github.com/hestiaos/hestiaos-community-edition.git

# Falls SSH verwendet wird: SSH-Key in WSL 2 einrichten
ssh-keygen -t ed25519 -C "your-email@example.com"
cat ~/.ssh/id_ed25519.pub
# Key zu GitHub hinzufügen: https://github.com/settings/keys
```

---

## 4. Docker Desktop

### Docker Desktop startet nicht

**Problem:** Docker Desktop hängt beim Start.

**Lösung:**

1. WSL 2 als Backend aktivieren (Docker Desktop → Settings → Resources → WSL Integration)
2. Ubuntu-24.04 in WSL Integration aktivieren
3. Docker Desktop neu starten
4. Prüfen: `wsl -l -v` (beide sollten Version 2 sein)

### docker compose nicht gefunden

**Problem:** `docker compose` (v2) wird nicht erkannt.

**Lösung:**

```powershell
# Docker Desktop installieren (enthält docker compose v2)
# https://www.docker.com/products/docker-desktop/

# Prüfen
docker compose version
```

---

## 5. Dependencies

### pip install schlägt fehl

**Problem:** `pip install -r requirements-community.txt` bricht mit Fehler ab.

**Häufige Ursachen:**

1. **Fehlende Build-Tools (Windows):**

```powershell
# Microsoft C++ Build Tools installieren
# https://visualstudio.microsoft.com/visual-cpp-build-tools/
```

1. **numpy/nomic Fehler (Windows):**

```powershell
# Python 3.12+ verwenden (nomic unterstützt 3.12)
python --version
```

1. **Berechtigungsfehler:**

```powershell
# Virtual Environment verwenden
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements-community.txt
```

### SDK-Installation fehlgeschlagen

**Problem:** `pip install -e ../sdk` schlägt fehl.

**Lösung:**

```bash
# Prüfen, ob setup.py existiert
ls ../sdk/setup.py

# Falls nicht: SDK-Komponente gemäß Edition-Build-Pipeline bereitstellen
```

---

## 6. Core

### Core startet nicht

**Problem:** `make start-core` zeigt Fehler.

**Lösung:**

```bash
# Prüfen, ob Dependencies installiert sind
pip list | grep -i "fastapi\|uvicorn\|pydantic"

# Fehlende Dependencies installieren
pip install -r requirements-community.txt

# Core im Debug-Modus starten
cd ../hestiaos-core
python -m uvicorn core.main:app --host 127.0.0.1 --port 8000 --log-level debug
```

### Health-Check schlägt fehl

**Problem:** `make check` zeigt "Core nicht erreichbar".

**Lösung:**

```bash
# Prüfen, ob Core läuft
curl http://127.0.0.1:8000/health

# Falls nicht: Core starten
make start-core

# Port prüfen
ss -tlnp | grep 8000
```

---

## 7. Edition-Manifest / Component-Lock

### Validierung schlägt fehl

**Problem:** `make validate` zeigt Fehler.

**Lösung:**

```bash
# Manifest-Struktur prüfen
cat edition-manifest.yaml
# Erwartet: edition: community, publication_status: public

# Lock-Struktur prüfen
python -c "import json; d=json.load(open('component-lock.json')); print(len(d['components']), 'Komponenten')"

# Validator manuell ausführen (Validatoren werden von der Edition-Build-Pipeline
# bereitgestellt und sind nicht Teil dieser Public-Komposition)
# python <pfad-zur-pipeline>/tools/validate_edition_manifest.py edition-manifest.yaml
# python <pfad-zur-pipeline>/tools/validate_component_lock.py component-lock.json
```

---

## 8. Sonstiges

### Git: "Host key verification failed"

**Problem:** Erster Git-Clone fragt nach Host-Key-Bestätigung.

**Lösung:**

```bash
# Einmalig bestätigen
git clone https://github.com/hestiaos/hestiaos-community-edition.git
# Oder: known_hosts automatisch akzeptieren
GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone <repo-url>
```

### Make nicht gefunden (Windows)

**Problem:** `make` ist kein Befehl unter Windows.

**Lösung:**

```powershell
# Option 1: Chocolatey
choco install make

# Option 2: WSL 2 verwenden (make ist vorinstalliert)
wsl

# Option 3: Befehle manuell ausführen
pip install -r requirements-community.txt
pip install -e ../sdk
pip install -e ../hestiaos-core
```

### PowerShell Execution Policy

**Problem:** PowerShell-Skripte können nicht ausgeführt werden.

**Lösung:**

```powershell
# Execution Policy für aktuelle Session setzen
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Prüfen
Get-ExecutionPolicy
```

---

## Support

- **Issles**: [github.com/hestiaos/hestiaos-community-edition/issues](https://github.com/hestiaos/hestiaos-community-edition/issues)
- **Quickstart**: [`quickstart.md`](quickstart.md)
- **Deployment Guide**: [`windows-deployment-guide.md`](windows-deployment-guide.md)
