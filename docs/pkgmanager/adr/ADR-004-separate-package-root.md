# ADR-004: Use a separate package root (`pkgroot/`), not the existing `external/` directory

**Status**: Accepted  
**Date**: 2026-10-23  
**Milestone**: M1

## Context

Freetz-NG already has a runtime extension mechanism: `rc.external` (in `make/pkgs/mod/files/root/etc/init.d/rc.external`). It:
- Reads `*.pkg` files from `$MOD_EXTERNAL_DIRECTORY` (default `/var/media/ftp/uStor01/external`)
- Creates symlinks from the USB directory into `/mod/etc/init.d/`, `/mod/usr/lib/cgi-bin/`, etc.
- Calls `rc.<pkg> load` for each listed package

Using this mechanism would avoid introducing new boot integration points.

However, the existing `external/` mechanism has fundamental differences from what the PRD requires:
- No version management or package database
- No integrity checking (no digests, no signatures)
- No dependency resolution
- `.pkg` files are plain text name lists, not archives
- No path isolation — packages write directly into the USB filesystem without a controlled root
- Not designed for binary packages (only init scripts and CGI pages)

## Decision

Use a separate package root: `<USB>/pkgroot/` (default `/var/media/ftp/uStor01/pkgroot`). The `external/` mechanism is left entirely unchanged.

## Rationale

- **No interference**: existing `external/` packages continue to work exactly as before. No regression risk.
- **Isolation**: `pkgroot/` has its own `database/` subdirectory, making it possible to reason about and recover state independently of the `external/` symlink graph.
- **Different semantics**: `external/` is for router-aware services (init scripts, CGI pages). `pkgroot/` is for installable binary packages (executables, libraries, config).
- **PRD requirement**: "Keep runtime package files isolated from AVM/Freetz-NG firmware files." The existing `external/` mechanism creates symlinks into `/mod/` which is the Freetz overlay — that would violate isolation.

## Consequences

- **Positive**: clean separation of concerns; existing users of `external/` are unaffected.
- **Negative**: administrators need to understand two separate USB extension mechanisms. This is documented in `docs/pkgmanager/setup.md`.
- **Future**: a possible M5+ integration could bridge the two mechanisms (e.g., runtime-installed packages that also register a CGI page), but this requires careful design and is explicitly deferred.
