# HestiaOS Community Edition — Component Startup Order

> Definiert die Start-Reihenfolge und Abhängigkeiten der 3 Community-Komponenten.

## Abhängigkeitsgraph

```
sdk (Bibliothek)
  ↑ keine Laufzeit-Abhängigkeit
  └── wird importiert von CLI/Agent-Code

hestiaos-core (FastAPI :8000)
  ↑ keine Laufzeit-Abhängigkeit
  └── mcp-server hängt von Core ab (Health-Check)

mcp-server (STDIO/HTTP :8001)
  ↑ depends_on: core (service_healthy)
  └── verbindet sich mit Core via HTTP
```

## Start-Reihenfolge

```
1. sdk installieren (pip install -e .)
       │
2. hestiaos-core installieren (pip install -e .)
       │
3. hestiaos-core starten (uvicorn core.main:app --port 8000)
       │
4. mcp-server starten (python wiki_mcp_server.py)
       │
5. Health-Check: curl http://127.0.0.1:8000/health
```

## Makefile-Targets

```bash
# Alle Komponenten installieren
make install

# Nur Core starten
make start-core

# Core + MCP starten
make start-core  # Terminal 1
make start-mcp   # Terminal 2

# Health-Check
make check
```

## Docker Compose

```bash
# Core + MCP mit Health-Check-Wartezeit
docker compose up -d

# Reihenfolge (docker-compose.yml):
# 1. core startet (Health-Check: curl /health, 15s Interval)
# 2. mcp-server startet NACH core healthy (depends_on: core condition: service_healthy)
```

## Port-Konfiguration

| Komponente | Standard-Port | Umgebungsvariable |
|---|---|---|
| hestiaos-core | 8000 | `CORE_PORT` |
| mcp-server | 8001 | `MCP_PORT` |

## Health-Endpunkte

| Komponente | Endpunkt | Erwartet |
|---|---|---|
| hestiaos-core | `GET /health` | `200 OK` |
| mcp-server | `GET /health` | `200 OK` |
