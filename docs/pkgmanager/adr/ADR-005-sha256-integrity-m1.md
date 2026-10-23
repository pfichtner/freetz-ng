# ADR-005: Use `sha256sum` (BusyBox) for payload integrity in M1; defer signatures to M3

**Status**: Accepted  
**Date**: 2026-10-23  
**Milestone**: M1 (integrity), M3 (signatures)

## Context

FR-007 requires: "Verify authenticated repository metadata and the package digest before installing."

The PRD also says: "Use a maintained cryptographic signature implementation available for the chosen target, or a narrowly scoped verifier with a documented threat model. Do not invent cryptography."

Available cryptographic tools on the target:
- `sha256sum` — BusyBox applet (`FREETZ_BUSYBOX___V138_SHA256SUM`), **not** in mandatory set but widely available
- `openssl` — optional Freetz-NG package (`make/pkgs/openssl/`); provides HMAC, RSA, EdDSA
- `libgcrypt` — available as a library package; no standalone binary
- `gpg`, `minisign`, `signify` — **not available** in Freetz-NG packages (confirmed by repository scan in M0)

## Decision

**M1/M2**: Use `sha256sum` for payload file integrity. The manifest (`CONTROL/manifest`) lists the sha256 of every payload file. `pkg install` verifies each file after extraction to a temp directory, before copying to the package root.

**M3**: Add cryptographic signature verification using the `openssl` command-line tool (RSA or EdDSA). The trust anchor (public key) is provisioned through the firmware build. This is documented as a hard dependency for M3.

## Threat model (M1/M2)

The sha256 digest check protects against:
- Accidental corruption of the archive during download or storage
- An attacker with write access to the USB storage device modifying a payload file after it was placed there

The sha256 check does **not** protect against:
- An attacker who controls both the `.fpkg` and its manifest (they can replace both)
- Replay attacks (installing an older valid package)

These gaps are explicitly left open until M3 adds signed repository metadata.

## Consequences

- **Positive**: no dependency on optional `openssl` package for basic installation; works even on minimal Freetz-NG builds.
- **Negative**: M1/M2 packages are not authenticated; administrators must transfer `.fpkg` files via trusted channels. This is documented as a known limitation in `docs/pkgmanager/setup.md`.
- **Requirement for M3**: `FREETZ_PACKAGE_OPENSSL=y` must be enabled in the firmware build for signature verification. The pkgmanager `Config.in` will add this as a `depends on` when M3 is implemented.
