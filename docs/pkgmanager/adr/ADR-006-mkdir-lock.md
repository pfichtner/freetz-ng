# ADR-006: Use `mkdir` as an advisory lock for concurrent operation prevention

**Status**: Accepted  
**Date**: 2026-10-23  
**Milestone**: M1

## Context

FR-security (PRD section 11): "Use a lock to prevent concurrent package operations."

On BusyBox/Linux systems, proper locking options include:
- `flock` (BusyBox applet, `FREETZ_BUSYBOX___V138_FLOCK`) — file descriptor lock
- `lockfile` (not in BusyBox)
- `mkdir` — atomic directory creation as advisory lock

`flock` is not in BusyBox's mandatory applet set. `mkdir` is POSIX and always available.

## Decision

Use `mkdir "$PKG_LOCK" 2>/dev/null` as the lock primitive. The lock directory is `$PKG_ROOT/database/.lock`. On success (directory created) the caller holds the lock; on failure (directory exists) another operation is in progress.

The lock holder removes the directory with `rmdir` on completion or failure.

## Rationale

- `mkdir` is atomic on POSIX filesystems (create-or-fail in one syscall).
- Available on all BusyBox targets without configuration.
- Lock directory is on the same filesystem as the database, so it is only present when the USB is mounted — it automatically disappears on unmount.
- Simple to inspect: `ls -la $PKG_ROOT/database/.lock` shows if a lock is held and by which process (if the PID is written there in a future enhancement).

## Consequences

- **Positive**: no external dependencies; works on FAT32 and ext4 (tested).
- **Negative**: not a robust lock. A crash leaves the lock directory behind. Recovery: `rmdir $PKG_ROOT/database/.lock` after confirming no pkg process is running. The `pkg status` command will report stale locks in a future enhancement.
- **Limitation**: does not provide deadlock detection or priority queuing. For M1, only one operation at a time is expected.
- **Future**: if M4 introduces concurrent read operations (e.g., `pkg list` while `pkg install` runs), upgrade to `flock` and make it a dependency.
