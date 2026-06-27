# Build & Verification

Community Edition artifacts are produced by the edition build pipeline
(`edition-build-pipeline`) from separately versioned components. This
repository declares the composition; it does not build from a vendored source
tree.

## Build flow (target)
```text
edition-manifest.yaml + config/community-profile.yaml
        ▼
Resolve components (hestiaos-core, mcp-server, sdk, released community modules)
        ▼
Edition build pipeline (edition-build-pipeline)
        ▼
Outputs:
  - component-lock.json      (real pinned versions + commit SHAs)
  - artifact hashes (sha256)
  - validation report
```

## Validation gates (required for any build)
- **Secret exclusion:** no `.env`, vault material, master keys, credential blobs,
  TLS private keys, or tokenized URLs.
- **Runtime-artifact exclusion:** no logs, databases/WAL files, caches, or
  build leftovers.
- **Public-exposure check:** secret scan + license/claim review before any
  public release.

## Reproducibility
Builds are intended to be reproducible: identical inputs (component versions +
profile) yield identical, hash-verifiable outputs. The example schema is in
`component-lock.example.json` (example only — no real versions asserted).

## Verifying a build (target)
1. Check the build's `component-lock.json` against expected component versions.
2. Verify artifact `sha256` hashes.
3. Confirm all validation gates report `passed`.
