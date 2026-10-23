# ADR-008: Use `files/runtime-root/` directory for declaring runtime package contents

**Status**: Accepted  
**Date**: 2026-10-23  
**Milestone**: M2

## Context

M2 requires: "Add a packaging target that stages only declared runtime files from an existing Freetz-NG package build."

The key design question is how a package author declares which files from their build go into the runtime `.fpkg`, given that:
- `files/root/` already exists as the firmware overlay directory (files placed here go into the squashfs firmware image)
- A runtime package may need a different (often smaller) subset of files than what is in the firmware build
- The build system uses `$(PKG)_DEST_DIR` as the cross-compiled output root

Options considered:

| Approach | Description | Trade-offs |
|---|---|---|
| Reuse `files/root/` | Runtime archive = firmware overlay | Simple, but conflates firmware and runtime contents |
| Explicit file list variable | `$(PKG)_RUNTIME_FILES = usr/bin/foo usr/lib/foo.so` | Flexible but verbose; breaks Makefile conventions |
| Separate `files/runtime-root/` directory | New directory parallel to `files/root/` | Clear separation; consistent with existing pattern |
| Use `$(PKG)_DEST_DIR` directly | Stage everything that was cross-compiled | May include dev headers, static libs, etc. not wanted at runtime |

## Decision

Use a `files/runtime-root/` directory parallel to `files/root/`. The build macro `runtime-pkg.mk` uses `$(PKG)_MAKE_DIR/files/runtime-root` as the staging root for `pkg-build`.

The `pkg-control` file (optional, at `make/pkgs/<name>/pkg-control`) provides additional metadata fields (Description, Depends) not otherwise available in the Makefile context.

## Rationale

- **Consistent pattern**: `files/root/` for firmware, `files/runtime-root/` for runtime — same concept, parallel directories, same author workflow.
- **Zero-change for existing packages**: packages without `files/runtime-root/` are completely unaffected by `runtime-pkg.mk`; the include only activates the `$(pkg)-fpkg` target.
- **Explicit declaration**: package authors consciously choose what goes into the runtime archive by placing files in `files/runtime-root/`. There is no automatic or magic file selection.
- **Opt-in integration**: `include $(MAKE_DIR)/pkgs/pkgmanager/runtime-pkg.mk` at the end of a `.mk` file is the only required change.

## Consequences

- **Positive**: zero regression risk for existing packages; clear author intent; simple tooling.
- **Negative**: for packages where runtime content = firmware content, authors must maintain two parallel directory trees. This is acceptable because such packages are expected to be the minority; most runtime packages will install a single binary, not a web UI.
- **Future**: if a package's `files/root/` and `files/runtime-root/` are identical, a `$(PKG)_RUNTIME_SAME_AS_FIRMWARE=y` convenience variable could be added. Deferred until there is a concrete need.
