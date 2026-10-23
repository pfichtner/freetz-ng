#!/bin/sh
# FR-002, FR-012: missing storage must cause install/remove to fail safely
# and must never initialise or overwrite the package database.

. "$(dirname "$0")/lib/assert.sh"

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
PKG="$REPO/make/pkgs/pkgmanager/files/root/usr/bin/pkg"
HELLO_FPKG="$REPO/tests/pkgmanager/fixtures/hello-pkg-1.0.0-arm-linux-uclibcgnueabi.fpkg"

TESTDIR=$(mktemp -d)
trap 'rm -rf "$TESTDIR"' EXIT

echo "=== Storage tests ==="

# --- Test: install fails when storage is not mounted ---
export PKG_ROOT="$TESTDIR/pkgroot"
export PKG_STORAGE_MOUNT="/no/such/mount"
export PKG_ARCH="arm-linux-uclibcgnueabi"

assert_exit "install fails (exit 2) when storage not mounted" 2 \
	"$PKG" install "$HELLO_FPKG"

assert_file_absent "no database directory created when storage missing" \
	"$TESTDIR/pkgroot/database"

# --- Test: list fails gracefully when storage not mounted ---
assert_exit "list fails (exit 2) when storage not mounted" 2 \
	"$PKG" list

# --- Test: remove fails gracefully when storage not mounted ---
assert_exit "remove fails (exit 2) when storage not mounted" 2 \
	"$PKG" remove hello-pkg

# --- Test: status reports not mounted (exit 0 — status never blocks) ---
assert_exit "status exits 0 even when storage not mounted" 0 \
	"$PKG" status

assert_output_contains "status reports NOT MOUNTED" "NOT MOUNTED" \
	"$PKG" status

summary
