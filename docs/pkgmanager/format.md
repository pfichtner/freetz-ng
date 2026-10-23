# Freetz-NG Runtime Package Format — Specification v1

This document defines the `.fpkg` archive format used by the Freetz-NG runtime package manager.

## Overview

A `.fpkg` file is a gzip-compressed POSIX tar archive with two top-level directories:

```
<name>-<version>-<arch>.fpkg
├── CONTROL/
│   ├── control          control metadata (key: value)
│   ├── manifest         payload digest manifest (sha256  ./relpath)
│   └── build-manifest   deterministic build record (optional)
└── data/
    └── ...              payload files, paths relative to the package root
```

The archive must use gzip compression (`tar czf`). Filenames encode package identity:
`<name>-<version>-<arch>.fpkg`

## Control File (`CONTROL/control`)

Required fields:

| Field | Type | Description |
|---|---|---|
| `Name` | string | Package name. Alphanumeric, dashes, underscores only. |
| `Version` | string | Package version (semver recommended). |
| `FormatVersion` | integer | Package format version. Must be `1`. |
| `Arch` | string | Target triplet, e.g. `arm-linux-uclibcgnueabi`. |
| `Description` | string | One-line human-readable description. |

Optional fields:

| Field | Type | Description |
|---|---|---|
| `Depends` | string | Comma-separated list of required package names. |
| `Conflicts` | string | Comma-separated list of conflicting package names. |
| `Target` | string | Specific router target, e.g. `fritzbox-7490` (reserved for M3+). |

Example:

```
Name: tcpdump
Version: 4.99.4
FormatVersion: 1
Arch: arm-linux-uclibcgnueabi
Description: Network packet analyzer
Depends: libpcap
```

All field names are case-sensitive. Unknown fields are ignored by the package manager.
The file must be encoded in UTF-8 with Unix line endings.

## Manifest (`CONTROL/manifest`)

One entry per payload file. Format: `<sha256hex>  <./relpath>` (two spaces).

```
a3f1...  ./usr/bin/tcpdump
b7c2...  ./usr/lib/libpcap.so.1
```

Paths must:
- Begin with `./`
- Be relative (no absolute paths, no `..` components)
- Reference only regular files (not directories, symlinks, or special files)

The manager verifies every file listed in the manifest before installation. Files present in `data/` but absent from the manifest are rejected. Files in the manifest but absent from `data/` are rejected.

## Payload (`data/`)

Payload files are installed under `<package-root>/`, reproducing their `data/` path. Example: `data/usr/bin/tcpdump` → `<pkgroot>/usr/bin/tcpdump`.

### Allowed entry types

| Type | Allowed |
|---|---|
| Regular file | Yes |
| Directory | Yes |
| Symbolic link | Yes, if target is relative and stays within `<pkgroot>/` |
| Hard link | Rejected |
| Character/block device | Rejected |
| FIFO / socket | Rejected |

### Path safety rules (enforced by `pkg install`)

- No absolute paths.
- No `..` components anywhere in the path.
- No path whose resolved location escapes `<pkgroot>/`.
- No duplicate destination paths that would overwrite a file owned by another package.

## Build Manifest (`CONTROL/build-manifest`)

Optional. Records information to make the build reproducible.

```
build-date: 2026-10-23
freetz-ng-rev: abc1234
source-files:
  a3f1...  ./usr/bin/tcpdump
  b7c2...  ./usr/lib/libpcap.so.1
```

The build manifest is stored in the archive but not required by the runtime installer.

## Filename Convention

`<name>-<version>-<arch>.fpkg`

- `name`: matches `Name:` in the control file
- `version`: matches `Version:` in the control file
- `arch`: matches `Arch:` in the control file

## Package Root Layout

Runtime packages install into a configurable writable package root (default: `/var/media/ftp/uStor01/pkgroot`). Recommended subdirectory layout:

| Path | Purpose |
|---|---|
| `<pkgroot>/bin/` | User executables |
| `<pkgroot>/sbin/` | System executables |
| `<pkgroot>/lib/` | Runtime libraries |
| `<pkgroot>/etc/` | Package-owned config defaults |
| `<pkgroot>/var/` | Package state / cache |
| `<pkgroot>/database/installed/` | Installed package records |
| `<pkgroot>/database/transactions/` | Transaction journal |
| `<pkgroot>/cache/` | Downloaded archives and repository metadata |

## Versioning Policy

- Format version `1` is the current version (Freetz-NG pkgmanager v1).
- The manager rejects packages with unsupported or future `FormatVersion` values.
- Packages must declare their exact `FormatVersion`. Unknown values are rejected.

## Tools

| Tool | Purpose |
|---|---|
| `tools/pkg-build` | Host-side: produces a `.fpkg` from a staging directory |
| `make/pkgs/pkgmanager/runtime-pkg.mk` | Build-system include: adds `$(pkg)-fpkg` target to any package |
| `/usr/bin/pkg` | Target-side: install, list, remove, info, status |
