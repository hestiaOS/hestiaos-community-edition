#!/usr/bin/env bash
# ============================================================================
# HestiaOS Community Edition — Prerequisites Check
# ============================================================================
# Phase 1 — Edition Build Pipeline
#
# Prüft, ob alle Voraussetzungen für die Community Edition erfüllt sind:
#   - Python 3.10+
#   - Git
#   - pip
#   - make
#   - curl (optional, für Health-Checks)
#   - Docker + Docker Compose (optional, für Container-Deployment)
#   - WSL 2 (optional, nur auf Windows)
#
# Exit-Codes:
#   0 — Alle Voraussetzungen erfüllt
#   1 — Kritische Voraussetzung fehlt
#   2 — Optionale Komponente fehlt (Warnung)
#
# Usage:
#   ./scripts/check-prerequisites.sh
#   ./scripts/check-prerequisites.sh --verbose
# ============================================================================

set -euo pipefail

# ── Konfiguration ──────────────────────────────────────────────────────────
VERBOSE=false
EXIT_CODE=0
MIN_PYTHON="3.10"

# Farben
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Argumente parsen ───────────────────────────────────────────────────────
for arg in "$@"; do
    case "$arg" in
        --verbose|-v) VERBOSE=true ;;
        --help|-h)
            echo "Usage: $0 [--verbose] [--help]"
            exit 0
            ;;
    esac
done

# ── Hilfsfunktionen ────────────────────────────────────────────────────────
pass() {
    echo -e "  ${GREEN}✅${NC} $1"
    [[ "$VERBOSE" == true ]] && echo "     $2"
}

warn() {
    echo -e "  ${YELLOW}⚠️  $1${NC}"
    [[ "$VERBOSE" == true ]] && echo "     $2"
    EXIT_CODE=2
}

fail() {
    echo -e "  ${RED}❌ $1${NC}"
    [[ "$VERBOSE" == true ]] && echo "     $2"
    EXIT_CODE=1
}

check_cmd() {
    local cmd="$1"
    local name="$2"
    local critical="${3:-true}"
    local hint="${4:-}"

    if command -v "$cmd" &>/dev/null; then
        local version
        version=$("$cmd" --version 2>&1 | head -n1)
        pass "$name" "$version"
        return 0
    else
        if [[ "$critical" == "true" ]]; then
            fail "$name — NICHT GEFUNDEN" "$hint"
        else
            warn "$name — nicht gefunden (optional)" "$hint"
        fi
        return 1
    fi
}

check_python_version() {
    local py_cmd="$1"
    local version
    version=$("$py_cmd" --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -n1)
    local major_minor
    major_minor=$(echo "$version" | cut -d. -f1,2)

    if [[ "$(echo -e "$major_minor\n$MIN_PYTHON" | sort -V | head -n1)" == "$MIN_PYTHON" ]] \
        || [[ "$major_minor" == "$MIN_PYTHON" ]]; then
        pass "$py_cmd $version" "Python $version >= $MIN_PYTHON ✓"
        return 0
    else
        fail "Python $version — Version $MIN_PYTHON+ erforderlich" \
            "Installiere Python $MIN_PYTHON+ von https://www.python.org/downloads/"
        return 1
    fi
}

# ── Header ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   HestiaOS Community Edition — Prerequisites Check     ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── 1. Python ──────────────────────────────────────────────────────────────
echo -e "${CYAN}📋 Python${NC}"
echo "   Mindestversion: $MIN_PYTHON"

if command -v python3 &>/dev/null; then
    check_python_version "python3"
elif command -v python &>/dev/null; then
    check_python_version "python"
else
    fail "Python — NICHT GEFUNDEN" \
        "Installiere Python $MIN_PYTHON+ von https://www.python.org/downloads/"
fi

# pip prüfen
if command -v pip3 &>/dev/null; then
    pass "pip3" "$(pip3 --version 2>&1 | head -n1)"
elif command -v pip &>/dev/null; then
    pass "pip" "$(pip --version 2>&1 | head -n1)"
else
    fail "pip — NICHT GEFUNDEN" "Installiere pip: python3 -m ensurepip --upgrade"
fi

echo ""

# ── 2. System-Tools ────────────────────────────────────────────────────────
echo -e "${CYAN}🔧 System-Tools${NC}"

check_cmd "git" "Git" "true" \
    "Installiere Git: https://git-scm.com/downloads"

check_cmd "make" "GNU Make" "true" \
    "Installiere make: apt install build-essential (Linux) / choco install make (Windows)"

check_cmd "curl" "curl" "false" \
    "Optional — wird für Health-Checks verwendet"

echo ""

# ── 3. Docker (optional) ──────────────────────────────────────────────────
echo -e "${CYAN}🐳 Docker (optional — für Container-Deployment)${NC}"

check_cmd "docker" "Docker" "false" \
    "Installiere Docker: https://docs.docker.com/get-docker/"

if command -v docker &>/dev/null; then
    # Docker Compose prüfen (v2 ist in docker integriert)
    if docker compose version &>/dev/null; then
        pass "Docker Compose" "$(docker compose version 2>&1)"
    elif docker-compose --version &>/dev/null; then
        pass "docker-compose" "$(docker-compose --version 2>&1)"
    else
        warn "Docker Compose — nicht gefunden" \
            "Installiere Docker Compose: https://docs.docker.com/compose/install/"
    fi
fi

echo ""

# ── 4. WSL 2 (nur Windows) ────────────────────────────────────────────────
echo -e "${CYAN}🪟 WSL 2 (optional — nur für Windows 11)${NC}"

if [[ "$(uname -r)" =~ microsoft ]]; then
    pass "WSL 2" "Läuft auf WSL 2 (Windows Subsystem for Linux)"
elif [[ "$(uname -s)" == "Linux" ]]; then
    pass "Linux" "$(uname -r) — WSL 2 auf Windows nicht nötig"
elif [[ "$(uname -s)" == "MINGW"* ]] || [[ "$(uname -s)" == "MSYS"* ]]; then
    warn "WSL 2 — nicht erkannt" \
        "Installiere WSL 2: wsl --install (PowerShell als Admin)"
else
    warn "WSL 2 — nicht anwendbar" "Unbekanntes Betriebssystem: $(uname -s)"
fi

echo ""

# ── 5. Repository-Struktur ────────────────────────────────────────────────
echo -e "${CYAN}📁 Repository-Struktur${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMUNITY_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$COMMUNITY_DIR/.." && pwd)"

check_dir() {
    local dir="$1"
    local name="$2"
    if [[ -d "$dir" ]]; then
        pass "$name" "$dir"
    else
        fail "$name — NICHT GEFUNDEN" "Erwartet unter: $dir"
    fi
}

check_file() {
    local file="$1"
    local name="$2"
    if [[ -f "$file" ]]; then
        pass "$name" "$file"
    else
        fail "$name — NICHT GEFUNDEN" "Erwartet unter: $file"
    fi
}

check_dir "$COMMUNITY_DIR" "hestiaos-community-edition"
check_file "$COMMUNITY_DIR/edition-manifest.yaml" "edition-manifest.yaml"
check_file "$COMMUNITY_DIR/component-lock.json" "component-lock.json"
check_file "$COMMUNITY_DIR/requirements-community.txt" "requirements-community.txt"
check_dir "$REPO_ROOT/sdk" "sdk"
check_file "$REPO_ROOT/sdk/setup.py" "sdk/setup.py"
check_dir "$REPO_ROOT/hestiaos-core" "hestiaos-core"
check_file "$REPO_ROOT/hestiaos-core/setup.py" "hestiaos-core/setup.py"
check_dir "$REPO_ROOT/mcp-server" "mcp-server"

echo ""

# ── Ergebnis ───────────────────────────────────────────────────────────────
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
case "$EXIT_CODE" in
    0)
        echo -e "${GREEN}✅ Alle Voraussetzungen erfüllt — Community Edition bereit!${NC}"
        echo ""
        echo "   Nächste Schritte:"
        echo "     make install      # Dependencies + Komponenten installieren"
        echo "     make validate     # Edition-Manifest + Lock validieren"
        echo "     make start-core   # Core starten"
        echo "     make check        # Health-Check"
        ;;
    2)
        echo -e "${YELLOW}⚠️  Alle kritischen Voraussetzungen erfüllt, aber optionale Komponenten fehlen.${NC}"
        echo -e "${YELLOW}   Die Community Edition kann trotzdem verwendet werden.${NC}"
        ;;
    1)
        echo -e "${RED}❌ Kritische Voraussetzungen fehlen — bitte installieren und erneut prüfen.${NC}"
        ;;
esac
echo ""

exit "$EXIT_CODE"
