#!/usr/bin/env bash
# ============================================================================
# HestiaOS Community Edition — Core Start Script
# ============================================================================
# Phase 2 — Edition Build Pipeline
#
# Startet hestiaos-core (FastAPI/Uvicorn) mit venv-Aktivierung.
#
# Usage:
#   ./scripts/start-core.sh                  # Start auf Port 8000
#   CORE_PORT=8001 ./scripts/start-core.sh   # Alternativer Port
#   CORE_HOST=0.0.0.0 ./scripts/start-core.sh # Auf allen Interfaces
#
# Environment:
#   CORE_PORT  — Port (default: 8000)
#   CORE_HOST  — Host (default: 127.0.0.1)
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMUNITY_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$COMMUNITY_DIR/.." && pwd)"
CORE_DIR="$REPO_ROOT/hestiaos-core"
VENV_DIR="$COMMUNITY_DIR/.venv"

CORE_PORT="${CORE_PORT:-8000}"
CORE_HOST="${CORE_HOST:-127.0.0.1}"
CORE_APP="${CORE_APP:-core.bootstrap.app_factory:create_ce_app()}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ── venv prüfen ────────────────────────────────────────────────────────────
if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo -e "${YELLOW}🔧 venv nicht gefunden — führe 'make install' aus...${NC}"
    cd "$COMMUNITY_DIR" && make install
fi

# ── Core-Verzeichnis prüfen ────────────────────────────────────────────────
if [ ! -d "$CORE_DIR" ]; then
    echo -e "${RED}❌ hestiaos-core nicht gefunden unter $CORE_DIR${NC}"
    echo "Bitte stelle sicher, dass alle Repos geklont sind."
    exit 1
fi

# ── Edition-Environment ────────────────────────────────────────────────────
export HESTIAOS_EDITION=community
export HESTIAOS_ENV=development

# ── Start ──────────────────────────────────────────────────────────────────
echo -e "${YELLOW}🚀 Starte hestiaos-core auf $CORE_HOST:$CORE_PORT...${NC}"
echo -e "   App:     $CORE_APP"
echo -e "   Edition: $HESTIAOS_EDITION"
echo ""

cd "$CORE_DIR"
source "$VENV_DIR/bin/activate"

exec uvicorn "$CORE_APP" \
    --host "$CORE_HOST" \
    --port "$CORE_PORT" \
    --reload \
    --log-level info
