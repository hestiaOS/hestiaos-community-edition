#!/usr/bin/env bash
# ============================================================================
# HestiaOS Community Edition — MCP Server Start Script
# ============================================================================
# Phase 2 — Edition Build Pipeline
#
# Startet mcp-server (Wiki MCP Server) mit venv-Aktivierung.
#
# Usage:
#   ./scripts/start-mcp.sh
#
# Environment:
#   MCP_PORT  — Port (default: 8001, sofern vom Server unterstützt)
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMUNITY_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$COMMUNITY_DIR/.." && pwd)"
MCP_DIR="$REPO_ROOT/mcp-server"
VENV_DIR="$COMMUNITY_DIR/.venv"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ── venv prüfen ────────────────────────────────────────────────────────────
if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo -e "${YELLOW}🔧 venv nicht gefunden — führe 'make install' aus...${NC}"
    cd "$COMMUNITY_DIR" && make install
fi

# ── MCP-Verzeichnis prüfen ─────────────────────────────────────────────────
if [ ! -d "$MCP_DIR" ]; then
    echo -e "${RED}❌ mcp-server nicht gefunden unter $MCP_DIR${NC}"
    echo "Bitte stelle sicher, dass alle Repos geklont sind."
    exit 1
fi

# ── Edition-Environment ────────────────────────────────────────────────────
export HESTIAOS_EDITION=community
export HESTIAOS_ENV=development

# ── Start ──────────────────────────────────────────────────────────────────
echo -e "${YELLOW}🚀 Starte mcp-server...${NC}"
echo -e "   Edition: $HESTIAOS_EDITION"
echo ""

cd "$MCP_DIR"
source "$VENV_DIR/bin/activate"

exec python wiki_mcp_server.py
