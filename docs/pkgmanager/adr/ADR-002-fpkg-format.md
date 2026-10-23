# ADR-002: Define a new `.fpkg` archive format rather than reusing OpenWrt/Entware `.ipk`

**Status**: Accepted  
**Date**: 2026-10-23  
**Milestone**: M1/M2

## Context

The PRD requires: "The coding agent must evaluate whether an existing lightweight format can be reused safely, but must not assume that OpenWrt/Entware packages are binary-compatible."

Candidate formats evaluated:

| Format | Used by | Binary-compatible? | Issues |
|---|---|---|---|
| `.ipk` (ar + data.tar.gz + control.tar.gz) | OpenWrt, Entware | No | ABI/libc mismatch; `opkg` not present on target |
| `.deb` | Debian | No | `dpkg` not available; format complexity |
| Plain tar.gz | Various | N/A | No standard control metadata structure |
| New `.fpkg` format | Freetz-NG | Native | Designed for this use case |

OpenWrt and Entware `.ipk` packages are linked against musl libc or a different uClibc ABI profile. Freetz-NG targets use uClibc (`arm-linux-uclibcgnueabi`), which is not binary-compatible with OpenWrt/musl packages. The `opkg` package manager is not present in Freetz-NG firmware.

## Decision

Define a new `.fpkg` format: a gzip-compressed tar archive with `CONTROL/` and `data/` top-level directories. The format is documented in `docs/pkgmanager/format.md`.

## Rationale

- **No binary compatibility claim**: a new format makes it impossible to accidentally install an OpenWrt/Entware package, which is explicitly forbidden by the PRD.
- **Minimal complexity**: two directories (CONTROL, data) are sufficient. No nested archives (unlike `.deb` and `.ipk`).
- **Forward-extensible**: the `FormatVersion` field allows future format changes without breaking the tooling contract.
- **Deterministic builds**: `--owner=0 --group=0 --numeric-owner` and sorted file listing enable reproducible archives.
- **BusyBox tar compatible**: BusyBox tar can read and write standard tar.gz; no special tools needed on target.

## Consequences

- **Positive**: clear separation from OpenWrt/Entware, simple tooling, extensible.
- **Negative**: no existing ecosystem; every package must be built specifically for Freetz-NG. This is a deliberate constraint per the PRD.
- **File extension**: `.fpkg` distinguishes runtime packages from Freetz-NG's existing `external/` mechanism which uses `.pkg` files as plain-text package name lists (not archives).
