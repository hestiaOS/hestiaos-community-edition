#!/usr/bin/env bash
# ============================================================================
# HestiaOS Community Edition — Start All Services
# ============================================================================
# Phase 2 — Edition Build Pipeline
#
# Startet Core und MCP-Server in der richtigen Reihenfolge:
#   1. Core (hestiaos-core) auf Port 8000
#   2. MCP-Server (mcp-server) auf Port 8001 (nach Core-Health)
#
# Usage:
#   ./scripts/start-all.sh                   # Beide Services starten
#   CORE_PORT=8001 ./scripts/start-all.sh    # Core auf anderem Port
#   ./scripts/start-all.sh --background      # Im Hintergrund starten
#   ./scripts/start-all.sh --stop            # Beide Services stoppen
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMUNITY_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VENV_DIR="$COMMUNITY_DIR/.venv"
PID_FILE="$COMMUNITY_DIR/.services.pid"

CORE_PORT="${CORE_PORT:-8000}"
CORE_HOST="${CORE_HOST:-127.0.0.1}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Hilfe ──────────────────────────────────────────────────────────────────
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "HestiaOS Community Edition — Start All Services"
    echo ""
    echo "Usage:"
    echo "  ./scripts/start-all.sh               Beide Services starten"
    echo "  ./scripts/start-all.sh --background   Im Hintergrund starten"
    echo "  ./scripts/start-all.sh --stop         Beide Services stoppen"
    echo "  ./scripts/start-all.sh --help         Diese Hilfe"
    exit 0
fi

# ── Stop ───────────────────────────────────────────────────────────────────
if [ "${1:-}" = "--stop" ]; then
    echo -e "${YELLOW}🛑 Stoppe Services...${NC}"
    if [ -f "$PID_FILE" ]; then
        while IFS= read -r pid; do
            if kill "$pid" 2>/dev/null; then
                echo -e "   ${GREEN}✅ Prozess $pid gestoppt${NC}"
            fi
        done < "$PID_FILE"
        rm -f "$PID_FILE"
    fi
    # Auch ohne PID-File: alle uvicorn/wiki_mcp_server Prozesse beenden
    pkill -f "uvicorn core.bootstrap" 2>/dev/null || true
    pkill -f "wiki_mcp_server.py" 2>/dev/null || true
    echo -e "${GREEN}✅ Alle Services gestoppt${NC}"
    exit 0
fi

# ── venv prüfen ────────────────────────────────────────────────────────────
if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo -e "${YELLOW}🔧 venv nicht gefunden — führe 'make install' aus...${NC}"
    cd "$COMMUNITY_DIR" && make install
fi

# ── Health-Check-Funktion ──────────────────────────────────────────────────
wait_for_health() {
    local host="$1"
    local port="$2"
    local name="$3"
    local retries="${4:-15}"
    local wait="${5:-2}"

    echo -e "   ${YELLOW}Warte auf $name ($host:$port)...${NC}"
    for i in $(seq 1 "$retries"); do
        if curl -sf "http://$host:$port/health" > /dev/null 2>&1; then
            echo -e "   ${GREEN}✅ $name ist bereit${NC}"
            return 0
        fi
        sleep "$wait"
    done
    echo -e "   ${RED}❌ $name nicht erreichbar nach ${retries}s${NC}"
    return 1
}

# ── Start ──────────────────────────────────────────────────────────────────
BACKGROUND=false
if [ "${1:-}" = "--background" ]; then
    BACKGROUND=true
fi

echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   HestiaOS Community Edition — Start All    ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# 1. Core starten
echo -e "${YELLOW}🚀 Starte hestiaos-core auf $CORE_HOST:$CORE_PORT...${NC}"
cd "$COMMUNITY_DIR"
source "$VENV_DIR/bin/activate"

if [ "$BACKGROUND" = true ]; then
    nohup "$SCRIPT_DIR/start-core.sh" > "$COMMUNITY_DIR/logs/core.log" 2>&1 &
    CORE_PID=$!
    echo "$CORE_PID" > "$PID_FILE"
    echo -e "   ${GREEN}✅ Core gestartet (PID: $CORE_PID)${NC}"
else
    # Im Vordergrund: Terminal 1 für Core
    echo -e "   ${YELLOW}Bitte starte Core in einem separaten Terminal:${NC}"
    echo -e "   ${CYAN}  ./scripts/start-core.sh${NC}"
    echo ""
fi

# Auf Core warten
wait_for_health "$CORE_HOST" "$CORE_PORT" "hestiaos-core" || true

# 2. MCP-Server starten
echo ""
echo -e "${YELLOW}🚀 Starte mcp-server...${NC}"

if [ "$BACKGROUND" = true ]; then
    nohup "$SCRIPT_DIR/start-mcp.sh" > "$COMMUNITY_DIR/logs/mcp.log" 2>&1 &
    MCP_PID=$!
    echo "$MCP_PID" >> "$PID_FILE"
    echo -e "   ${GREEN}✅ MCP-Server gestartet (PID: $MCP_PID)${NC}"
else
    echo -e "   ${YELLOW}Bitte starte MCP-Server in einem separaten Terminal:${NC}"
    echo -e "   ${CYAN}  ./scripts/start-mcp.sh${NC}"
fi

echo ""
echo -e "${GREEN}✅ Start abgeschlossen${NC}"
echo -e "   Core:       http://$CORE_HOST:$CORE_PORT/health"
echo -e "   MCP-Server: http://127.0.0.1:8001/health"
echo ""
echo -e "   ${YELLOW}Zum Stoppen: ./scripts/start-all.sh --stop${NC}"
