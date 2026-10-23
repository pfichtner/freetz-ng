# ADR-007: Two-pass validation — inspect archive listing before extraction, then verify digests

**Status**: Accepted  
**Date**: 2026-10-23  
**Milestone**: M1

## Context

FR-010 requires: "Reject absolute paths, '..' traversal, duplicate conflicting paths, unexpected device nodes, unsafe symlinks, and unsupported archive entry types."

FR-010 also notes: "Never unpack an archive directly over the package root without validating every entry first."

Validation options:
1. **Single-pass streaming extraction**: parse archive headers while extracting; abort and delete partial files on violation. Complex to implement correctly in shell.
2. **Two-pass with temp directory**: (a) list entries and check paths, (b) extract all to temp dir, (c) verify digests and check file types, (d) copy clean files to package root.
3. **Three-pass**: list → check paths → extract to temp → check types/digests → move.

## Decision

Use a two-pass approach:
1. **Pass 1 — listing**: `tar tzf "$archive"` → `grep` for dangerous paths (absolute, `..` components). Reject before any extraction.
2. **Pass 2 — temp extraction**: `tar xzf "$archive" -C "$tmpdir"` → check for device nodes (`find ... -type c -o -type b`), verify sha256 of every payload file against the manifest.
3. **Install**: copy validated files from temp dir to package root (atomic rename where possible).

## Rationale

- **Pass 1 (listing)**: fast, catches the most obvious attacks without writing any files. A 100MB archive with a traversal entry is rejected in seconds.
- **Temp directory**: isolates the extraction environment. Files are never written to the package root until validation is complete. Temp dir is under `/tmp` (RAM tmpfs typically), not on the USB device.
- **Device node check after extraction**: BusyBox tar's `t` (list) mode does not show file types for special files reliably. Checking after extraction via `find -type c -o -type b` is reliable.
- **PRD compliance**: satisfies "Never unpack an archive directly over the package root without validating every entry first."

## Consequences

- **Positive**: simple to reason about; validation is independent of installation. Clean failure modes.
- **Negative**: requires enough RAM to hold the extracted archive in `/tmp`. Large packages (e.g., 50 MB) may exhaust RAM on routers with limited memory. A future enhancement could stream to temp storage on USB, but this adds complexity and is deferred.
- **Temp dir cleanup**: always removed in `_cleanup_install`, even on error. A crash leaves the temp dir in `/tmp` until next reboot (tmpfs).
