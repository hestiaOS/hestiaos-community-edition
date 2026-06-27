# HestiaOS — Community Edition

> **Status: developer preview / early public composition profile.**
> This repository is an **edition composition**, not the platform source code.

The Community Edition defines *which* released HestiaOS components are composed
into a free, minimal distribution, plus its public documentation and
build/verification metadata. The executable components themselves live in
separate, versioned repositories and are assembled reproducibly by the edition
build pipeline.

## What this repository is
- An **edition manifest** (`edition-manifest.yaml`) declaring the Community composition.
- A **component lock example** (`component-lock.example.json`) — schema/example only.
- A **community profile** (`config/community-profile.yaml`) — default, secret-free configuration.
- **Public documentation** (`docs/`): architecture overview, community scope, build & verification.

## What this repository is NOT
- Not a copy of the internal development platform.
- Not a place for `core/`, API, or frontend source trees (those live in their own component repositories).
- Not a production-ready release. No security or performance guarantees are made here.

## Components (expected, composed via the build pipeline)
See `edition-manifest.yaml`. Builds are produced by the edition build pipeline from
versioned components; this repository does not vendor or pin real component
versions yet.

## License
Apache-2.0 — see `LICENSE`.

## Security
See `SECURITY.md` for the responsible disclosure process.

## Provenance
This repository was created clean-room. See `PROVENANCE.md` — no legacy git
history, tags, release artifacts, or source projection were carried over.
