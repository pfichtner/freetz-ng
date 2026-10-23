# ADR-001: Shell script for the `pkg` CLI (M1)

**Status**: Accepted  
**Date**: 2026-10-23  
**Milestone**: M1

## Context

The `pkg` CLI must run on the selected target (ARM 32-bit Fritz!Box, BusyBox ash shell). The implementation language could be:
- A POSIX shell script
- A compiled C binary (cross-compiled with the Freetz-NG toolchain)
- A script in an interpreted language (Python, Lua, etc.)

The PRD explicitly prohibits Python and Perl unless already present on the target and the trade-off is documented. The target has BusyBox ash with `ASH_BASH_COMPAT` enabled. All required operations (file I/O, archive inspection, sha256sum, process management) are available as BusyBox applets or POSIX shell builtins.

## Decision

Use a POSIX sh script (BusyBox ash compatible) for M1 and M2. Defer a compiled binary to M3+ if cryptographic operations require it.

## Rationale

- **Zero cross-compilation**: the script installs without a build step, which simplifies the firmware packaging target (`pkgmanager.mk` is trivial).
- **Portability**: runs on all four supported architectures (ARM, AArch64, MIPS, x86) without architecture-specific builds.
- **Auditability**: administrators can read and verify the tool directly on the router.
- **Available tools**: sha256sum, tar, gzip, grep, sed, awk, find, mkdir, mv — all confirmed present in BusyBox 1.38.

## Consequences

- **Positive**: no cross-compiler dependency, simpler firmware inclusion, portable.
- **Negative**: shell scripts cannot call libssl/libgcrypt directly; cryptographic signature verification (M3) will require a compiled helper or an external binary (e.g., OpenSSL command-line tool, which is an optional Freetz-NG package). This is documented as a prerequisite for M3.
- **Constraint**: scripts must avoid bash arrays, `mapfile`, `declare -A`, and process substitution `<(...)`. String operations use `sed`/`awk` rather than bash-only parameter expansion where compatibility is uncertain.
