# ADR-003: Use `/proc/mounts` for USB storage detection, not path existence

**Status**: Accepted  
**Date**: 2026-10-23  
**Milestone**: M1

## Context

FR-002 requires: "Verify the mount is active and points to the intended device/filesystem; do not rely on path existence alone."

On Freetz-NG routers, the USB mount point directory (`/var/media/ftp/uStor01`) is created by `libmodmount.sh:do_mount_locked` before `mount` is called. The directory therefore exists even when no device is mounted. Checking `[ -d "$PKG_STORAGE_MOUNT" ]` alone would return true even with no USB device present, leading to database operations on a non-persistent path.

Alternative approaches considered:
1. `[ -d "$PKG_STORAGE_MOUNT" ]` — path existence only (insufficient)
2. Parse `/proc/mounts` for the exact mount point
3. Use `mountpoint $path` (BusyBox applet, available but not in mandatory set)
4. Use `findmnt $path` (not in BusyBox; external package required)

## Decision

Parse `/proc/mounts` with `grep -q " $PKG_STORAGE_MOUNT " /proc/mounts` (space-delimited). This matches the second field of `/proc/mounts` entries exactly and confirms a real mounted filesystem.

Additionally check `[ -d "$PKG_ROOT" ]` to ensure the package root has been initialized.

## Rationale

- `/proc/mounts` is always present on Linux (including Freetz-NG routers).
- Space-delimited grep avoids false positives from paths that are prefixes of the target (e.g., `/var/media/ftp/uStor01extra` would not match ` /var/media/ftp/uStor01 `).
- No additional BusyBox applets needed (grep is mandatory).
- Matches the pattern already used in `libmodmount.sh:do_mount_locked` (line 127): `mount | grep -q "$mnt_dev on /var/media/"`.

## Consequences

- **Positive**: reliable, no false positives from leftover mount directories.
- **Negative**: the configured `PKG_STORAGE_MOUNT` must exactly match the second field in `/proc/mounts`. Trailing slashes or alternate representations fail silently. Documented as a configuration requirement.
- **Implication**: `pkg status` reports the storage state, giving administrators visibility into detection results.
