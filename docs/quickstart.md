# HestiaOS Community Edition — Quickstart

> **"Es läuft in 5 Minuten"** — Lokale Entwicklungsumgebung einrichten.

## Voraussetzungen

- **Python 3.10+** ([python.org](https://www.python.org/downloads/))
- **Git** ([git-scm.com](https://git-scm.com/downloads))
- **make** (Linux: `build-essential`, Windows: `choco install make`, macOS: `xcode-select --install`)

Prüfe mit: [`scripts/check-prerequisites.sh`](../scripts/check-prerequisites.sh)

## Installation (3 Minuten)

```bash
# 1. Repository klonen
git clone https://github.com/hestiaos/hestiaos-community-edition.git
cd hestiaos-community-edition

# 2. Dependencies installieren
pip install -r requirements-community.txt

# 3. SDK + Core im Editable-Mode installieren
cd ../sdk && pip install -e . && cd ../hestiaos-community-edition
cd ../hestiaos-core && pip install -e . && cd ../hestiaos-community-edition

# 4. Validieren
make validate
```

## Core starten (1 Minute)

```bash
make start-core
# → http://127.0.0.1:8000
# → http://127.0.0.1:8000/health
```

## Health-Check (1 Minute)

```bash
make check
# ✅ Core antwortet
# ⚠️  MCP-Server läuft nicht (starte mit 'make start-mcp')
```

## Nächste Schritte

| Thema | Dokumentation |
|---|---|
| Vollständige Windows 11 Anleitung | [`windows-deployment-guide.md`](windows-deployment-guide.md) |
| Komponenten-Start-Reihenfolge | [`component-startup-order.md`](component-startup-order.md) |
| Windows-Konfiguration | [`config-template-windows.md`](config-template-windows.md) |
| Bekannte Probleme | [`troubleshooting.md`](troubleshooting.md) |
| Build-Pipeline (Makefile) | [`../Makefile`](../Makefile) |
| Docker Deployment | [`../docker-compose.yml`](../docker-compose.yml) |

## Architektur (Überblick)

```
┌─────────────┐     HTTP      ┌──────────────┐     STDIO     ┌────────────────┐
│  CLI/Agent   │ ──────────▶  │  hestiaos-core     │ ────────────▶ │  mcp-server │
│  (sdk)    │ ◀────────── │  :8000        │ ◀──────────── │  (MCP Tools)   │
└─────────────┘              └──────────────┘               └────────────────┘
```

## Support

- **Issues**: [github.com/hestiaos/hestiaos-community-edition/issues](https://github.com/hestiaos/hestiaos-community-edition/issues)
- **Governance**: `../docs/governance-rules.md`
