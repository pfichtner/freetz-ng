# Freetz-NG Package Repository Format — Specification v1

This document defines the repository structure used by `pkg update` and `pkg install <name>`.

## Overview

A Freetz-NG package repository is a directory (served over HTTP/HTTPS or available locally) containing:

```
<repo-root>/
├── Release          signed metadata (ValidUntil, Sequence, SHA256-Packages)
├── Release.sig      detached Ed25519 signature over Release (base64-encoded)
├── Packages         package index (one stanza per .fpkg)
└── *.fpkg           package archives
```

## Release File

Plain text, UTF-8, Unix line endings.

```
FormatVersion: 1
Arch: arm-linux-uclibcgnueabi
Date: 2026-10-23T12:00:00Z
ValidUntil: 2027-10-23
Sequence: 1
SHA256-Packages: <sha256-hex-of-Packages-file>
BaseURL: https://example.com/freetz/arm/
```

| Field | Required | Description |
|---|---|---|
| `FormatVersion` | Yes | Must be `1`. |
| `Arch` | Yes | Target architecture this repository serves. |
| `Date` | Yes | ISO 8601 UTC publication timestamp. |
| `ValidUntil` | Yes | YYYY-MM-DD expiry date. `pkg update` rejects expired metadata. |
| `Sequence` | Yes | Monotonically increasing integer. `pkg update` rejects rollbacks. |
| `SHA256-Packages` | Yes | SHA-256 of the Packages file. Verified after Packages is downloaded. |
| `BaseURL` | No | Informational base URL for clients. |

## Release Signature

`Release.sig` is the detached Ed25519 signature over the entire `Release` file, base64-encoded (standard encoding, no line wrapping).

Generate:
```sh
openssl pkeyutl -sign -inkey repo-private.pem -rawin -in Release -out Release.sig.bin
base64 Release.sig.bin > Release.sig
```

Verify:
```sh
base64 -d Release.sig > Release.sig.bin
openssl pkeyutl -verify -pubin -inkey trusted.pub -rawin -in Release -sigfile Release.sig.bin
```

The client verifies the signature using the public key embedded in firmware at `$PKG_PUBKEY_FILE` (default `/etc/pkgmanager/trusted.pub`).

## Packages Index

One stanza per package, stanzas separated by a blank line.

```
Package: tcpdump
Version: 4.99.4
FormatVersion: 1
Arch: arm-linux-uclibcgnueabi
Description: Network packet analyzer
Depends: libpcap
Filename: tcpdump-4.99.4-arm-linux-uclibcgnueabi.fpkg
SHA256: <sha256-of-fpkg-file>
Size: 1234567

Package: hello-pkg
Version: 1.0.0
...
```

| Field | Required | Description |
|---|---|---|
| `Package` | Yes | Package name |
| `Version` | Yes | Package version |
| `FormatVersion` | Yes | Package format version (must be `1`) |
| `Arch` | Yes | Target architecture |
| `Description` | Yes | One-line description |
| `Depends` | No | Comma-separated dependency names |
| `Filename` | Yes | Archive filename relative to repo root |
| `SHA256` | Yes | SHA-256 of the .fpkg archive. Verified after download, against authenticated index. |
| `Size` | No | Archive size in bytes (informational) |

## Trust Model

```
firmware (read-only)  →  /etc/pkgmanager/trusted.pub  (Ed25519 public key)
repository admin      →  repo-private.pem             (Ed25519 private key, NOT in firmware)
                          │
                          ▼ signs
                         Release  ←  client verifies via trusted.pub
                          │
                          ▼ SHA256 hash covers
                         Packages  ←  client verifies hash against Release
                          │
                          ▼ SHA256 per entry covers
                         *.fpkg  ←  client verifies before installing
```

The client **never** installs a package solely because it was downloaded over HTTPS. Every step must pass signature/hash verification.

## Anti-Rollback Policy

The `Sequence` field is a monotonically increasing integer. `pkg update` records the last accepted sequence number in `<pkgroot>/cache/repo-sequence`. An incoming Release with `Sequence ≤` the cached value is rejected as a potential rollback attack.

Key rotation: issue a new Release with a higher Sequence. Old clients with a cached Sequence from before the rotation will accept the new Release as long as the new Sequence is higher.

## Key Rotation

1. Generate a new keypair.
2. Build and flash new firmware with the new `trusted.pub`.
3. Re-sign the repository Release with the new private key.
4. Increment `Sequence` to invalidate old cached signatures.

There is no online key transition mechanism in v1 — key rotation requires a firmware update. This is documented as a known limitation.

## Generating a Repository

Use `tools/repo-build`:

```sh
# Generate a keypair (once per repository)
openssl genpkey -algorithm ed25519 -out repo-private.pem
openssl pkey -in repo-private.pem -pubout -out trusted.pub
# Copy trusted.pub to make/pkgs/pkgmanager/files/root/etc/pkgmanager/trusted.pub

# Build packages and put .fpkg files in a directory
mkdir -p my-repo/
cp *.fpkg my-repo/

# Generate and sign the index
tools/repo-build my-repo/ repo-private.pem \
    --arch arm-linux-uclibcgnueabi \
    --valid-days 365 \
    --sequence 1

# Serve my-repo/ over HTTPS
```

## Client Configuration

Set in `/mod/etc/conf/pkgmanager.cfg` on the router:

```sh
export PKG_REPO_URL='https://example.com/freetz/arm'
```

The public key (`trusted.pub`) is provisioned in firmware and read from `PKG_PUBKEY_FILE` (default `/etc/pkgmanager/trusted.pub`).
