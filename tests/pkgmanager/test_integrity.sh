#!/bin/sh
# FR-007: digest mismatch and wrong-arch archives must be rejected before extraction

. "$(dirname "$0")/lib/assert.sh"

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
PKG="$REPO/make/pkgs/pkgmanager/files/root/usr/bin/pkg"
FIXTURES="$REPO/tests/pkgmanager/fixtures"

TESTDIR=$(mktemp -d)
trap 'rm -rf "$TESTDIR"' EXIT

export PKG_ROOT="$TESTDIR/pkgroot"
export PKG_STORAGE_MOUNT="/"
export PKG_ARCH="arm-linux-uclibcgnueabi"
mkdir -p "$PKG_ROOT"

echo "=== Integrity / compatibility tests ==="

# --- wrong architecture ---
assert_exit "wrong-arch package rejected (exit 4)" 4 \
	"$PKG" install "$FIXTURES/hello-wrong-arch.fpkg"

assert_file_absent "no payload written for wrong-arch package" \
	"$PKG_ROOT/usr/bin/hello"

assert_file_absent "no database record for wrong-arch package" \
	"$PKG_ROOT/database/installed/hello-pkg"

# --- bad digest ---
assert_exit "bad-digest package rejected (exit 4)" 4 \
	"$PKG" install "$FIXTURES/bad-digest.fpkg"

assert_file_absent "no payload written for bad-digest package" \
	"$PKG_ROOT/usr/bin/hello"

assert_file_absent "no database record for bad-digest package" \
	"$PKG_ROOT/database/installed/hello-pkg"

# --- corrupted archive (not a gzip) ---
CORRUPT="$TESTDIR/corrupt.fpkg"
echo "this is not a tar.gz" > "$CORRUPT"
assert_exit "corrupt archive rejected (exit 4)" 4 \
	"$PKG" install "$CORRUPT"

assert_file_absent "no payload written for corrupt archive" \
	"$PKG_ROOT/usr/bin/hello"

summary
