# ADR-001: Community Edition Architecture

## Status

**Accepted** — 2026-06-23  
**Gate:** COMMUNITY-ALPHA-RELEASE-GATE (Phase 1)  
**Reviewer:** HestiaOS Governance Kernel

## Context

Die Community Edition ist die minimale, öffentliche Edition von HestiaOS. Sie ist
secret-free, local-first und enthält weder Enterprise- noch Science-Features.

Dieses ADR dokumentiert die Architekturentscheidungen, die bei der Erstanlage der
Edition getroffen wurden. Es erfüllt die ADR-Pflicht laut
Governance Rules §8
für den Übergang `draft → internal`.

### Ausgangslage

- Die Community Edition wurde aus dem HestiaOS-Monolithen extrahiert
  (siehe `community-edition-windows-deployment.md`).
- Der ursprüngliche Monolith enthielt alle Komponenten in einem
  Repository — die Edition trennt diese in eigenständige, versionierte Komponenten.
- Der Rollout auf dem Testsystem wurde erfolgreich abgeschlossen
  (`rollout-report-001.md` (intern, nicht mitgeliefert)).

## Decision

### 1. Komponenten-Modell

Die Community Edition besteht aus genau **drei Kern-Komponenten**:

| Komponente | Repository | Rolle | Provenance |
|---|---|---|---|
| **hestiaos-core** | `hestiaos-core/` | Governance Kernel, Execution Runtime | clean-room |
| **mcp-server** | `mcp-server/` | MCP Server & Tooling | clean-room |
| **sdk** | `sdk/` | Public SDK | clean-room |

Begründung:

- **hestiaos-core** ist essentiell — ohne den Governance Kernel läuft keine HestiaOS-Instanz.
- **mcp-server** ist essentiell — MCP ist das primäre Integrationsprotokoll.
- **sdk** ist essentiell — öffentliche API für Client-Anwendungen.

Alle drei Komponenten haben `provenance_class: clean-room`, d. h. sie wurden
aus dem Monolithen extrahiert und enthalten keine Drittanbieter-Artefakte.

### 2. Edition-Boundary

Die Edition-Boundary wird durch die Factory-Funktion
`create_ce_app()` definiert:

```python
def create_ce_app() -> FastAPI:
    """Erzeugt eine Community-Edition FastAPI-App (kein Enterprise, kein Science)."""
```

Diese Factory:

- Deaktiviert **Enterprise-Features** (`enterprise=False`)
- Deaktiviert **Science-Features** (`science=False`)
- Setzt den **Primary Model** auf `llama3.1:latest`
- Verwendet `DefaultPolicyProvider` (kein Enterprise Policy Provider)
- Initialisiert den `LicenseManager` mit der Edition `COMMUNITY`

Die Edition-Boundary wird durch den Health-Endpoint bestätigt:

```json
{"status":"ok","edition":"ce","enterprise":false,"science":false}
```

### 3. Build-Pipeline

Die Edition wird durch die Pipeline in
`edition-build-pipeline` komponiert und validiert:

1. **Validate**: `make validate` prüft Manifest, Lock und Prerequisites
2. **Install**: `make install` installiert alle Dependencies
3. **Test**: `make test` führt die Core-Tests aus (77/77 bestanden)
4. **Check**: `make check` validiert Core + MCP-Server Antworten
5. **Start**: `make start` startet Core + MCP-Server lokal

Die Pipeline ist **read-only** — sie führt keine Deployment-Skripte aus und
modifiziert keine Infrastruktur.

### 4. Lizenz- und Sicherheitsmodell

| Aspekt | Entscheidung |
|---|---|
| **Lizenz hestiaos-core** | Apache-2.0 |
| **Lizenz sdk** | Apache-2.0 |
| **Lizenz mcp-server** | Apache 2.0 |
| **Secrets** | Keine — alle Secrets werden über Environment-Variablen injiziert |
| **Netzwerk-Prinzipale** | Keine — Agents sind keine Netzwerk-Prinzipale |
| **Local-first** | Default-Bind auf `127.0.0.1` |
| **Datenbank** | SQLite (`data/artifacts.db`) — lokal, kein externes DBMS |

### 5. Deployment-Modell

Die Community Edition unterstützt zwei Deployment-Modi:

1. **Lokal (Development)**:
   - `make install && make start`
   - Core auf `127.0.0.1:8000`
   - MCP-Server im STDIO-Modus

2. **Docker (Container)**:
   - `docker compose up`
   - Core + MCP-Server als Container
   - Konfiguration über `docker-compose.yml` und `.env`

### 6. Ausgeschlossene Komponenten

Folgende Komponenten sind explizit ausgeschlossen (siehe
[`edition-manifest.yaml`](../edition-manifest.yaml:29)):

- **Enterprise-only modules** (z. B. enterprise-edition)
- **Science-only / research modules** (z. B. science-edition)
- **Internal ultimate-dev modules** (z. B. agents, plugins)
- **Internal infrastructure / operations tooling** (z. B. platform-modules, platform-api)

## Consequences

### Positive

- **Minimale Angriffsfläche**: Nur 3 Komponenten, keine Secrets, local-first.
- **Klare Edition-Boundary**: Enterprise/Science-Features sind zur Compile-Zeit
  deaktiviert — kein Runtime-Feature-Flag-Risiko.
- **Reproduzierbarer Build**: component-lock.json fixiert Commit-Hashes und
  Artifact-Hashes aller Komponenten.
- **Governance-konform**: ADR-Pflicht erfüllt, design_gate approved,
  publication_status public.

### Negative

- **Kein Enterprise Policy Provider**: Nur `DefaultPolicyProvider` verfügbar —
  keine erweiterten Policy-Features.
- **Kein Science-Stack**: EMBER-Benchmarks, Semantik-Engine und
  Research-Workflows sind nicht verfügbar.
- **Legacy-Bypass-Warnings**: `CoreMemory` und `EpisodicMemory` sind
  Legacy-Proxies — verursachen Warnings, aber nicht blockierend.

### Risks

| Risiko | Mitigation |
|---|---|
| **Fehlende `__init__.py` in hestiaos-core** | Behoben — 53 `__init__.py` erstellt |
| **Editable Install Finder broken** | Workaround via `.pth`-Datei aktiv |
| **Docker-Daemon nicht verfügbar** | Lokaler Dev-Mode als Fallback |
| **MCP-Server STDIO-only** | HTTP-basierte Tool-Calls nicht getestet |

## Review Requirements

1. ✅ Governance Kernel bestätigt die Edition-Architektur
2. ✅ `design_gate` ist auf `approved` gesetzt
3. ✅ Alle 3 Komponenten sind `validated/clean/cleared`
4. ✅ Rollout auf Testsystem erfolgreich
5. 🔄 Validatoren-Lauf (Phase 2 des COMMUNITY-ALPHA-RELEASE-GATE)

## Referenzen

- [`edition-manifest.yaml`](../edition-manifest.yaml) — Edition-Manifest
- [`component-lock.json`](../component-lock.json) — Component-Lock
- `rollout-report-001.md` (intern, nicht mitgeliefert) — Rollout-Report
- `create_ce_app()` — CE-Factory
- `community-alpha-release-gate.md` — Release-Gate-Plan
- `governance-rules.md` — Governance-Regeln
- `release-process.md` — Release-Prozess
