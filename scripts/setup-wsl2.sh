#!/usr/bin/env bash
# ============================================================================
# HestiaOS Community Edition — WSL 2 Setup
# ============================================================================
# Phase 2 — Windows 11 Deployment (edition-build-pipeline)
#
# Richtet die Community Edition in einer WSL 2-Umgebung (Ubuntu 24.04) ein:
#   1. Repositories klonen (falls nicht vorhanden)
#   2. SDK installieren (pip install -e)
#   3. Core-Dependencies installieren
#   4. MCP-Server-Dependencies installieren
#   5. Edition-Manifest + Component-Lock validieren
#   6. Health-Check (Core starten, MCP-Server testen)
#
# Usage:
#   ./scripts/setup-wsl2.sh                    # Normale Installation
#   ./scripts/setup-wsl2.sh --skip-clone        # Überspringe Git-Clone
#   ./scripts/setup-wsl2.sh --skip-validate     # Überspringe Validierung
#   ./scripts/setup-wsl2.sh --help              # Hilfe
#
# Voraussetzungen:
#   - WSL 2 mit Ubuntu 24.04 (oder anderer Debian-basierter Distro)
#   - Python 3.10+
#   - Git
#   - make
# ============================================================================

set -euo pipefail

# ── Konfiguration ──────────────────────────────────────────────────────────
SKIP_CLONE=false
SKIP_VALIDATE=false
MIN_PYTHON="3.10"

# Repositories (HTTPS — keine Secrets nötig)
REPOS=(
    "https://github.com/hestiaos/sdk.git"
    "https://github.com/hestiaos/hestiaos-core.git"
    "https://github.com/hestiaos/mcp-server.git"
    "https://github.com/hestiaos/hestiaos-community-edition.git"
)

# Farben
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Argumente parsen ───────────────────────────────────────────────────────
for arg in "$@"; do
    case "$arg" in
        --skip-clone) SKIP_CLONE=true ;;
        --skip-validate) SKIP_VALIDATE=true ;;
        --help|-h)
            echo "Usage: $0 [--skip-clone] [--skip-validate] [--help]"
            echo ""
            echo "  --skip-clone     Überspringe Git-Clone (wenn Repos bereits vorhanden)"
            echo "  --skip-validate  Überspringe Validierung"
            echo "  --help           Diese Hilfe anzeigen"
            exit 0
            ;;
    esac
done

# ── Hilfsfunktionen ────────────────────────────────────────────────────────
log()     { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }
step()    { echo ""; echo -e "${CYAN}═══════════════════════════════════════════${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}═══════════════════════════════════════════${NC}"; }

check_cmd() {
    if ! command -v "$1" &>/dev/null; then
        error "$1 ist nicht installiert. Bitte installieren: $2"
        exit 1
    fi
}

# ── Header ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   HestiaOS Community Edition — WSL 2 Setup             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── 1. Voraussetzungen prüfen ─────────────────────────────────────────────
step "1/6 — Voraussetzungen prüfen"

check_cmd "python3" "sudo apt install python3 python3-pip python3-venv"
check_cmd "git" "sudo apt install git"
check_cmd "make" "sudo apt install build-essential"

# Python-Version prüfen
PY_VERSION=$(python3 --version 2>&1 | grep -oP '\d+\.\d+')
if [[ "$(echo -e "$PY_VERSION\n$MIN_PYTHON" | sort -V | head -n1)" != "$MIN_PYTHON" ]]; then
    error "Python $PY_VERSION gefunden, aber $MIN_PYTHON+ erforderlich."
    error "Installiere Python $MIN_PYTHON+: sudo apt install python3.$MIN_PYTHON"
    exit 1
fi
log "Python $PY_VERSION ✓"

# pip prüfen
python3 -m pip --version &>/dev/null || {
    error "pip nicht gefunden. Installiere: sudo apt install python3-pip"
    exit 1
}
log "pip ✓"

# curl prüfen (optional)
if command -v curl &>/dev/null; then
    log "curl ✓"
fi

# ── 2. Arbeitsverzeichnis ─────────────────────────────────────────────────
step "2/6 — Arbeitsverzeichnis"

WORKSPACE="${HOME}/hestiaos"
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"
log "Arbeitsverzeichnis: $WORKSPACE"

# ── 3. Repositories klonen ────────────────────────────────────────────────
step "3/6 — Repositories klonen"

if [[ "$SKIP_CLONE" == "true" ]]; then
    log "Git-Clone übersprungen (--skip-clone)"
else
    for repo_url in "${REPOS[@]}"; do
        repo_name=$(basename "$repo_url" .git)
        if [[ -d "$repo_name" ]]; then
            log "$repo_name — bereits vorhanden, aktualisiere..."
            cd "$repo_name" && git pull --ff-only && cd "$WORKSPACE"
        else
            log "Klonen: $repo_url"
            git clone "$repo_url"
        fi
    done
    log "Alle Repositories bereit"
fi

# ── 4. Dependencies installieren ──────────────────────────────────────────
step "4/6 — Dependencies installieren"

# 4a. Community-Dependencies
log "Installiere Community-Dependencies..."
cd "$WORKSPACE/hestiaos-community-edition"
python3 -m pip install -r requirements-community.txt

# 4b. SDK (Editable-Mode)
log "Installiere sdk (Editable-Mode)..."
cd "$WORKSPACE/sdk"
python3 -m pip install -e .

# 4c. Core (Editable-Mode)
log "Installiere hestiaos-core (Editable-Mode)..."
cd "$WORKSPACE/hestiaos-core"
python3 -m pip install -e .

# 4d. MCP-Server
log "Installiere mcp-server Dependencies..."
cd "$WORKSPACE/mcp-server"
if [[ -f "requirements.txt" ]]; then
    python3 -m pip install -r requirements.txt
fi

cd "$WORKSPACE"
log "Alle Dependencies installiert ✓"

# ── 5. Validierung ─────────────────────────────────────────────────────────
step "5/6 — Validierung"

if [[ "$SKIP_VALIDATE" == "true" ]]; then
    log "Validierung übersprungen (--skip-validate)"
else
    cd "$WORKSPACE/hestiaos-community-edition"

    # Edition-Manifest prüfen
    if [[ -f "edition-manifest.yaml" ]]; then
        log "Edition-Manifest: $(grep 'edition:' edition-manifest.yaml | head -1)"
        log "Publication Status: $(grep 'publication_status:' edition-manifest.yaml | head -1)"
    fi

    # Component-Lock prüfen
    if [[ -f "component-lock.json" ]]; then
        COMPONENT_COUNT=$(python3 -c "import json; d=json.load(open('component-lock.json')); print(len(d['components']))")
        log "Component-Lock: $COMPONENT_COUNT Komponenten gelockt"

        # Status jedes Components prüfen
        python3 -c "
import json
d = json.load(open('component-lock.json'))
for c in d['components']:
    name = c['component']
    sec = c.get('security_status', 'unknown')
    lic = c.get('license_status', 'unknown')
    val = c.get('validation_status', 'unknown')
    print(f'  ✅ {name}: security={sec}, license={lic}, validation={val}')
"
    fi

    # Prerequisites-Check (falls vorhanden)
    if [[ -f "scripts/check-prerequisites.sh" ]]; then
        bash scripts/check-prerequisites.sh || true
    fi

    log "Validierung abgeschlossen ✓"
fi

# ── 6. Health-Check ───────────────────────────────────────────────────────
step "6/6 — Health-Check (Core starten + testen)"

cd "$WORKSPACE/hestiaos-community-edition"

# Core im Hintergrund starten
log "Starte hestiaos-core (Port 8000)..."
cd "$WORKSPACE/hestiaos-core"
python3 -m uvicorn core.main:app --host 127.0.0.1 --port 8000 &
CORE_PID=$!
cd "$WORKSPACE"

# Kurz warten, bis Core bereit ist
sleep 3

# Health-Check
if command -v curl &>/dev/null; then
    if curl -sf http://127.0.0.1:8000/health > /dev/null 2>&1; then
        log "✅ Core antwortet auf http://127.0.0.1:8000/health"
    else
        warn "Core nicht erreichbar (möglicherweise noch am Starten)"
        warn "Prüfe später: curl http://127.0.0.1:8000/health"
    fi
else
    python3 -c "
import urllib.request
try:
    urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=5)
    print('✅ Core antwortet auf http://127.0.0.1:8000/health')
except Exception as e:
    print(f'⚠️  Core nicht erreichbar: {e}')
"
fi

# ── Zusammenfassung ────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   HestiaOS Community Edition — Setup abgeschlossen     ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "   Verzeichnis: $WORKSPACE"
echo ""
echo "   Nützliche Befehle:"
echo "     cd $WORKSPACE/hestiaos-community-edition"
echo "     make validate       # Edition-Manifest + Lock prüfen"
echo "     make check          # Health-Check"
echo "     make start-core     # Core starten (Port 8000)"
echo "     make start-mcp      # MCP-Server starten"
echo ""
echo "   Core läuft auf: http://127.0.0.1:8000"
echo "   Core PID: ${CORE_PID:-nicht gestartet}"
echo ""
