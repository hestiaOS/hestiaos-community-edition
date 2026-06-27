# Community Scope

Defines what is in and out of scope for the Community Edition.

## In scope
- Free, minimal HestiaOS composition (developer preview).
- Default governance policies and a secret-free community profile.
- Public documentation (architecture, scope, build & verification).
- Reproducible build/verification metadata.

## Out of scope
- Enterprise-only capabilities (compliance, SLA, business features).
- Science/research-only components and experimental harnesses.
- Internal "ultimate-dev" full-system composition.
- Internal infrastructure, operations tooling, and non-public modules.

## Composition principle
The Community Edition includes only **edition-neutral kernel components** and
**explicitly released community modules**. Anything enterprise-, science-, or
internal-only is excluded by the edition profile and the build pipeline's
exclusion gates.

## Versioning
- Edition profile version: see `config/community-profile.yaml`.
- Component versions: resolved at build time (see `component-lock.example.json`
  for the schema; real locks are produced by the build pipeline).
