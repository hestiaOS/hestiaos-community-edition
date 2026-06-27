# Architecture Overview — Community Edition

The Community Edition is a **composition** of released HestiaOS components, not a
standalone codebase. This document gives a neutral, public overview.

## Layered model
```text
Edition composition (this repo: hestiaos-community-edition)
        │   declares which components + profile + build metadata
        ▼
Versioned components (separate repositories)
   ├── hestiaos-core              runtime, governance, state, execution
   ├── mcp-server        MCP server / tooling
   ├── sdk               public SDK
   ├── transition-planning-layer   plans state transitions (non-authoritative)
   └── released community modules (optional)
        │
        ▼
Edition build pipeline (edition-build-pipeline)
   → reproducible build, component lock, artifact hashes, validation report
```

## Key boundaries
- **hestiaos-core** is the authoritative runtime/governance/execution core.
- The **Transition Planning Layer** plans state transitions but makes **no**
  authoritative governance or execution decisions.
- Editions are **compositions**, not forks of the core.

## What the Community Edition aims to provide
- A free, minimal, local-first composition for evaluation and contribution.
- Public documentation and reproducible build/verification metadata.

## What it does not claim
- It is a **developer preview**. It makes no production-readiness, compliance,
  or absolute security/performance claims.
