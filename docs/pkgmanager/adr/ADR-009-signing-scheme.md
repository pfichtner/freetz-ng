# ADR-009: Ed25519 via `openssl pkeyutl` for repository metadata signing

**Status**: Accepted  
**Date**: 2026-10-23  
**Milestone**: M3  
**Supersedes**: ADR-005 (which deferred this decision)

## Context

M3 requires signed repository metadata. The signing scheme must:
- Be available as a command-line tool on the target (required for `pkg update` signature verification)
- Use a maintained implementation — no custom cryptography (PRD section 11)
- Have a small key size and fast verification (important on low-resource routers)
- Be available in the Freetz-NG package ecosystem

Options evaluated:

| Scheme | Tool | Key size | Notes |
|---|---|---|---|
| RSA-2048 + SHA-256 | openssl dgst -sign | 2048-bit | Widely supported, large key |
| ECDSA P-256 + SHA-256 | openssl dgst -sign | 256-bit | Supported in OpenSSL 1.0+ |
| Ed25519 | openssl pkeyutl | 256-bit | Requires OpenSSL 1.1.1+; fast; no hash parameter needed |
| minisign / signify | not in Freetz-NG | 256-bit | Not available in Freetz-NG packages (confirmed M0 recon) |
| GnuPG | not in Freetz-NG | varies | Not available in Freetz-NG packages (confirmed M0 recon) |

`minisign` and `signify` are specifically designed for software signing with a simpler API than OpenSSL, but neither exists in the Freetz-NG package tree (confirmed by M0 repository scan). Implementing a custom verifier would violate the PRD's "Do not invent cryptography" requirement.

OpenSSL is an optional Freetz-NG package (`make/pkgs/openssl/`, versions up to 3.5.9). Versions 1.1.1+ support Ed25519.

## Decision

Use **Ed25519** via `openssl pkeyutl` for signing and verifying repository Release files.

- Sign (host, `tools/repo-build`): `openssl pkeyutl -sign -inkey privkey.pem -in Release -out Release.sig.bin`
- Verify (target, `pkg update`): `openssl pkeyutl -verify -pubin -inkey trusted.pub -in Release -sigfile Release.sig.bin`
- Signature encoding: base64 (standard, no line wrap) stored as `Release.sig`
- Minimum OpenSSL version: 3.0 (required for `-rawin` flag in `pkeyutl`; 1.1.1 used a different, now-deprecated API)

## Rationale

- **Ed25519 over RSA**: smaller keys (32 bytes vs 256 bytes), faster verification, no side-channel vulnerability to timing attacks, no need to choose a hash function separately.
- **Ed25519 over ECDSA P-256**: Ed25519 has a simpler and safer API (deterministic signing; no nonce; `pkeyutl` takes the message directly without a separate hash step).
- **`openssl pkeyutl` over `openssl dgst`**: `openssl dgst -sign` with Ed25519 has version-dependent behavior; `pkeyutl` is the canonical interface for EdDSA.
- **Separate signature file**: `Release.sig` is detached from `Release`, keeping the Release file human-readable and verifiable independently.

## Threat model

The signature protects:
- Repository metadata integrity (ValidUntil, Sequence, SHA256-Packages)
- Binding of package names/versions to their archive digests

The chain: `Release` (signed) → `Packages` (hash-bound to Release) → each `.fpkg` (hash-bound to Packages entry) → payload files (sha256-bound to CONTROL/manifest).

The scheme does **not** protect against:
- An attacker who has compromised the private key (requires key rotation and firmware update)
- Rollback to a valid older Release — mitigated by the Sequence anti-rollback check

## Consequences

- **Firmware requirement**: `FREETZ_PACKAGE_OPENSSL=y` must be included in firmware builds that use `pkg update`. This is noted in `Config.in` (comment) and `docs/pkgmanager/setup.md`.
- **Key rotation**: requires a firmware update to provision a new `trusted.pub`. No online key transition in v1 (see `docs/pkgmanager/repository.md`).
- **Key generation**: the private key must be generated, stored, and managed by the repository administrator. It must never be embedded in firmware. `tools/repo-build` uses it only on the host side.
