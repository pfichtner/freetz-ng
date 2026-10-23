#!/bin/sh
# Golden path: install, list, info, execute, remove, reinstall

. "$(dirname "$0")/lib/assert.sh"

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
PKG="$REPO/make/pkgs/pkgmanager/files/root/usr/bin/pkg"
HELLO_FPKG="$REPO/tests/pkgmanager/fixtures/hello-pkg-1.0.0-arm-linux-uclibcgnueabi.fpkg"

TESTDIR=$(mktemp -d)
trap 'rm -rf "$TESTDIR"' EXIT

# Use / as the fake storage mount (always in /proc/mounts on Linux)
export PKG_ROOT="$TESTDIR/pkgroot"
export PKG_STORAGE_MOUNT="/"
export PKG_ARCH="arm-linux-uclibcgnueabi"
mkdir -p "$PKG_ROOT"

echo "=== Install / list / remove tests ==="

# --- install ---
assert_exit "install hello-pkg exits 0" 0 \
	"$PKG" install "$HELLO_FPKG"

assert_file_exists "payload installed at pkgroot/usr/bin/hello" \
	"$PKG_ROOT/usr/bin/hello"

assert_file_exists "database record exists after install" \
	"$PKG_ROOT/database/installed/hello-pkg/control"

assert_file_exists "manifest exists after install" \
	"$PKG_ROOT/database/installed/hello-pkg/manifest"

assert_file_absent "no transaction journal left after clean install" \
	"$PKG_ROOT/database/transactions/hello-pkg.in-progress"

# --- list ---
assert_output_contains "list shows hello-pkg after install" "hello-pkg" \
	"$PKG" list

assert_output_contains "list shows version 1.0.0" "1.0.0" \
	"$PKG" list

# --- info ---
assert_output_contains "info shows Name field" "Name: hello-pkg" \
	"$PKG" info hello-pkg

assert_output_contains "info shows Version field" "Version: 1.0.0" \
	"$PKG" info hello-pkg

# --- execute ---
assert_output_contains "installed hello script produces expected output" \
	"Hello from Freetz-NG" \
	"$PKG_ROOT/usr/bin/hello"

# --- double install rejected ---
assert_exit "double install fails (exit 5)" 5 \
	"$PKG" install "$HELLO_FPKG"

# --- remove ---
assert_exit "remove hello-pkg exits 0" 0 \
	"$PKG" remove hello-pkg

assert_file_absent "payload removed after pkg remove" \
	"$PKG_ROOT/usr/bin/hello"

assert_file_absent "database record removed after pkg remove" \
	"$PKG_ROOT/database/installed/hello-pkg"

# --- list shows nothing after remove ---
assert_output_contains "list shows no packages after remove" "No packages" \
	"$PKG" list

# --- reinstall after remove ---
assert_exit "reinstall after remove exits 0" 0 \
	"$PKG" install "$HELLO_FPKG"

assert_file_exists "payload reinstalled correctly" \
	"$PKG_ROOT/usr/bin/hello"

summary
