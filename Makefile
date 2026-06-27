# HestiaOS Community Edition — Build Pipeline & Tooling
# ======================================================
# Phase 1 — Edition Build Pipeline
#
# Targets:
#   validate     — Edition-Manifest + Component-Lock validieren + Prerequisites
#   install      — Alle Python-Dependencies + Komponenten in venv installieren
#   install-sdk  — sdk im Editable-Mode installieren
#   install-core — hestiaos-core im Editable-Mode installieren
#   install-mcp  — mcp-server Dependencies installieren
#   test         — SDK-Tests + Core-Import-Tests ausführen
#   start-core   — hestiaos-core (FastAPI) starten
#   start-mcp    — mcp-server (MCP STDIO) starten
#   check        — Health-Check aller Komponenten
#   all          — Vollständiger Build + Validate + Start
#   clean        — Build-Artefakte + venv entfernen
#
# Usage:
#   make install       # Einmalig: venv + Dependencies + alle Komponenten installieren
#   make validate      # Edition-Manifest + Component-Lock + Prerequisites prüfen
#   make test          # SDK-Tests + Core-Import-Tests ausführen
#   make start-core    # Core starten (Port 8000)
#   make check         # Health-Check
#   make all           # Kompletter Durchlauf

SHELL := /bin/bash
.ONESHELL:

# ── Pfade ──────────────────────────────────────────────────────────────────
COMMUNITY_DIR    := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
REPO_ROOT        := $(abspath $(COMMUNITY_DIR)/..)
SDK_DIR          := $(REPO_ROOT)/sdk
CORE_DIR         := $(REPO_ROOT)/hestiaos-core
MCP_DIR          := $(REPO_ROOT)/mcp-server
VENV             := $(COMMUNITY_DIR)/.venv
REQUIREMENTS     := $(COMMUNITY_DIR)/requirements-community.txt
MANIFEST         := $(COMMUNITY_DIR)/edition-manifest.yaml
LOCK             := $(COMMUNITY_DIR)/component-lock.json

# ── Tools ──────────────────────────────────────────────────────────────────
VALIDATE_MANIFEST := $(REPO_ROOT)/edition-build-pipeline/tools/validate_edition_manifest.py
VALIDATE_LOCK     := $(REPO_ROOT)/edition-build-pipeline/tools/validate_component_lock.py
PREREQS_SCRIPT    := $(COMMUNITY_DIR)/scripts/check-prerequisites.sh
PYTHON           := python3
PIP              := $(VENV)/bin/pip
PYTHON_VENV      := $(VENV)/bin/python

# ── Core-Server ────────────────────────────────────────────────────────────
CORE_PORT        ?= 8000
CORE_HOST        ?= 127.0.0.1
CORE_APP         ?= core.main:app

# ── Farben (für hübsche Ausgabe) ──────────────────────────────────────────
GREEN  := \033[0;32m
YELLOW := \033[1;33m
RED    := \033[0;31m
CYAN   := \033[0;36m
NC     := \033[0m

.PHONY: all validate validate-manifest validate-lock validate-prereqs
.PHONY: install install-deps install-sdk install-core install-mcp
.PHONY: test start-core start-mcp check check-core check-mcp clean help

# ── venv (automatische Erstellung) ─────────────────────────────────────────
$(VENV)/bin/activate:
	@echo -e "$(YELLOW)🔧 Erzeuge venv in $(VENV)...$(NC)"
	$(PYTHON) -m venv "$(VENV)"
	@echo -e "$(GREEN)✅ venv erstellt$(NC)"

# ── Standard-Target ────────────────────────────────────────────────────────
all: validate install test
	@echo -e "$(GREEN)✅ Community Edition — Build abgeschlossen$(NC)"

# ── Hilfe ──────────────────────────────────────────────────────────────────
help:
	@echo -e "$(CYAN)HestiaOS Community Edition — Build Pipeline$(NC)"
	@echo ""
	@echo "  make validate       Edition-Manifest + Component-Lock + Prerequisites prüfen"
	@echo "  make install        venv + alle Dependencies + Komponenten installieren"
	@echo "  make install-sdk    sdk im Editable-Mode installieren"
	@echo "  make install-core   hestiaos-core im Editable-Mode installieren"
	@echo "  make install-mcp    mcp-server Dependencies installieren"
	@echo "  make test           SDK-Tests + Core-Import-Tests ausführen"
	@echo "  make start-core     hestiaos-core starten (Port $(CORE_PORT))"
	@echo "  make start-mcp      mcp-server starten"
	@echo "  make check          Health-Check aller Komponenten"
	@echo "  make clean          venv + Build-Artefakte entfernen"
	@echo "  make all            Kompletter Durchlauf (validate + install + test)"
	@echo ""

# ── Validierung ────────────────────────────────────────────────────────────
validate: validate-prereqs validate-manifest validate-lock
	@echo -e "$(GREEN)✅ Validierung erfolgreich$(NC)"

validate-prereqs:
	@echo -e "$(YELLOW)🔍 Prüfe Systemvoraussetzungen...$(NC)"
	@if [ -f "$(PREREQS_SCRIPT)" ]; then \
		bash "$(PREREQS_SCRIPT)" || [ $$? -le 2 ] || exit 1; \
	else \
		echo -e "$(YELLOW)⚠️  Prerequisites-Skript nicht gefunden — überspringe$(NC)"; \
	fi

validate-manifest:
	@echo -e "$(YELLOW)🔍 Validiere Edition-Manifest...$(NC)"
	@if [ -f "$(VALIDATE_MANIFEST)" ]; then
		$(PYTHON) "$(VALIDATE_MANIFEST)" "$(MANIFEST)"
	else
		@echo -e "$(YELLOW)⚠️  Validator nicht gefunden — überspringe Manifest-Validierung$(NC)"
	fi

validate-lock:
	@echo -e "$(YELLOW)🔍 Validiere Component-Lock...$(NC)"
	@if [ -f "$(VALIDATE_LOCK)" ]; then
		$(PYTHON) "$(VALIDATE_LOCK)" "$(LOCK)"
	else
		@echo -e "$(YELLOW)⚠️  Validator nicht gefunden — überspringe Lock-Validierung$(NC)"
	fi

# ── Installation ───────────────────────────────────────────────────────────
install: $(VENV)/bin/activate install-deps install-sdk install-core install-mcp
	@echo -e "$(GREEN)✅ Alle Komponenten installiert$(NC)"

install-deps: $(VENV)/bin/activate
	@echo -e "$(YELLOW)📦 Installiere Community-Dependencies...$(NC)"
	$(PIP) install -r "$(REQUIREMENTS)"

install-sdk: $(VENV)/bin/activate
	@echo -e "$(YELLOW)📦 Installiere sdk (Editable-Mode)...$(NC)"
	cd "$(SDK_DIR)" && $(PIP) install -e .

install-core: $(VENV)/bin/activate
	@echo -e "$(YELLOW)📦 Installiere hestiaos-core (Editable-Mode)...$(NC)"
	cd "$(CORE_DIR)" && $(PIP) install -e .

install-mcp: $(VENV)/bin/activate
	@echo -e "$(YELLOW)📦 Installiere mcp-server Dependencies...$(NC)"
	@if [ -f "$(MCP_DIR)/requirements.txt" ]; then
		$(PIP) install -r "$(MCP_DIR)/requirements.txt"
	else
		@echo -e "$(YELLOW)⚠️  Keine requirements.txt in mcp-server gefunden$(NC)"
	fi

# ── Tests ──────────────────────────────────────────────────────────────────
test: $(VENV)/bin/activate test-sdk test-core
	@echo -e "$(GREEN)✅ Alle Tests bestanden$(NC)"

test-sdk: $(VENV)/bin/activate
	@echo -e "$(YELLOW)🧪 Führe SDK-Tests aus...$(NC)"
	cd "$(SDK_DIR)" && $(PYTHON_VENV) -m pytest tests/ -v --tb=short

test-core: $(VENV)/bin/activate
	@echo -e "$(YELLOW)🧪 Prüfe Core-Import...$(NC)"
	$(PYTHON_VENV) -c "import core; print('✅ Core import erfolgreich')"

# ── Start ──────────────────────────────────────────────────────────────────
start-core:
	@echo -e "$(YELLOW)🚀 Starte hestiaos-core auf $(CORE_HOST):$(CORE_PORT)...$(NC)"
	cd "$(CORE_DIR)" && $(PYTHON_VENV) -m uvicorn "$(CORE_APP)" \
		--host "$(CORE_HOST)" \
		--port "$(CORE_PORT)" \
		--reload \
		--log-level info

start-mcp:
	@echo -e "$(YELLOW)🚀 Starte mcp-server...$(NC)"
	cd "$(MCP_DIR)" && $(PYTHON_VENV) wiki_mcp_server.py

# ── Health-Check ───────────────────────────────────────────────────────────
check: check-core check-mcp
	@echo -e "$(GREEN)✅ Health-Check abgeschlossen$(NC)"

check-core:
	@echo -e "$(YELLOW)🔍 Prüfe hestiaos-core auf $(CORE_HOST):$(CORE_PORT)...$(NC)"
	@if command -v curl &>/dev/null; then \
		curl -sf "http://$(CORE_HOST):$(CORE_PORT)/health" > /dev/null \
			&& echo -e "$(GREEN)  ✅ Core antwortet$(NC)" \
			|| echo -e "$(RED)  ❌ Core nicht erreichbar$(NC)"; \
	else \
		$(PYTHON_VENV) -c "import urllib.request, sys; urllib.request.urlopen('http://$(CORE_HOST):$(CORE_PORT)/health', timeout=5); print('✅ Core antwortet')" \
			|| echo -e "$(RED)  ❌ Core nicht erreichbar$(NC)"; \
	fi

check-mcp:
	@echo -e "$(YELLOW)🔍 Prüfe mcp-server...$(NC)"
	@if pgrep -f "wiki_mcp_server.py" &>/dev/null; then \
		echo -e "$(GREEN)  ✅ MCP-Server läuft$(NC)"; \
	else \
		echo -e "$(YELLOW)  ⚠️  MCP-Server läuft nicht (starte mit 'make start-mcp')$(NC)"; \
	fi

# ── Clean ──────────────────────────────────────────────────────────────────
clean:
	@echo -e "$(YELLOW)🧹 Entferne venv...$(NC)"
	rm -rf "$(VENV)"
	@echo -e "$(YELLOW)🧹 Entferne Build-Artefakte...$(NC)"
	find "$(COMMUNITY_DIR)" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find "$(COMMUNITY_DIR)" -type f -name "*.pyc" -delete 2>/dev/null || true
	find "$(COMMUNITY_DIR)" -type f -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find "$(SDK_DIR)" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find "$(SDK_DIR)" -type f -name "*.pyc" -delete 2>/dev/null || true
	find "$(SDK_DIR)" -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find "$(CORE_DIR)" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find "$(CORE_DIR)" -type f -name "*.pyc" -delete 2>/dev/null || true
	find "$(CORE_DIR)" -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	@echo -e "$(GREEN)✅ Clean abgeschlossen$(NC)"
