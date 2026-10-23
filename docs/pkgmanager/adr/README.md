# Architecture Decision Records — Freetz-NG Runtime Package Manager

| ADR | Title | Status | Milestone |
|---|---|---|---|
| [ADR-001](ADR-001-shell-script-cli.md) | Shell script for `pkg` CLI | Accepted | M1 |
| [ADR-002](ADR-002-fpkg-format.md) | New `.fpkg` format, not OpenWrt/Entware `.ipk` | Accepted | M1/M2 |
| [ADR-003](ADR-003-proc-mounts-detection.md) | `/proc/mounts` for USB storage detection | Accepted | M1 |
| [ADR-004](ADR-004-separate-package-root.md) | Separate `pkgroot/` instead of `external/` | Accepted | M1 |
| [ADR-005](ADR-005-sha256-integrity-m1.md) | `sha256sum` for M1 integrity; OpenSSL signatures deferred to M3 | Accepted | M1/M3 |
| [ADR-006](ADR-006-mkdir-lock.md) | `mkdir`-based advisory lock | Accepted | M1 |
| [ADR-007](ADR-007-two-pass-extraction.md) | Two-pass archive validation before installation | Accepted | M1 |
| [ADR-008](ADR-008-runtime-root-staging.md) | `files/runtime-root/` for declaring runtime package contents | Accepted | M2 |
| [ADR-009](ADR-009-signing-scheme.md) | Ed25519 via `openssl pkeyutl` for repository signing | Accepted | M3 |

## Open decisions (to be resolved in future milestones)

- **M3 (resolved)**: Ed25519 — see ADR-009.
- **M4**: Dependency resolution algorithm — topological sort in shell or compiled helper? How are circular dependencies detected and reported?
- **M4**: What is the user-edited config preservation policy during upgrade? (Merge, backup, replace-with-notice?)
