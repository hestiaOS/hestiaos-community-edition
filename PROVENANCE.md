# Provenance

## Clean-room creation
This repository was created **clean-room**. It does **not** inherit:
- any legacy git history,
- any old tags or release artifacts,
- any source-code projection of the internal development platform,
- any secrets, keys, vault data, TLS private keys, logs, or runtime artifacts.

## Why
A previous community distribution carried sensitive material and an
unsuitable history. To establish a clean public boundary, the Community Edition
is restarted as a thin **edition composition** repository rather than a copy of
the internal monolith.

## How builds are produced
Executable Community builds are intended to be produced reproducibly by the
edition build pipeline from **separately versioned components** (see
`edition-manifest.yaml`). This repository declares the composition; it does not
vendor component source.

- Component versions/locks: see `component-lock.example.json` (**example only** —
  no real versions or commit hashes are asserted yet).
- Build/verification process: see `docs/build-and-verification.md`.

## Status
`developer-preview`. No production-readiness, compliance, or security guarantees
are asserted by this repository.

## Repository visibility
Initial repository visibility: **private**. Public release requires explicit
security and publication review.
