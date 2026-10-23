#!/bin/sh
# rc.pkgmanager tests — run on host with a stub modlibrc environment.
# On a real router the full router environment is exercised by smoke tests;
# this suite covers the logic that does NOT depend on router-specific services.

. "$(dirname "$0")/lib/assert.sh"

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
RC_SCRIPT="$REPO/make/pkgs/pkgmanager/files/root/etc/init.d/rc.pkgmanager"

TESTDIR=$(mktemp -d)
trap 'rm -rf "$TESTDIR"' EXIT

# Self-contained modlibrc stub — no external sourcing needed.
STUB_MODLIBRC="$TESTDIR/stubs/modlibrc"
mkdir -p "$TESTDIR/stubs"
cat > "$STUB_MODLIBRC" <<'STUBEOF'
loglib_system() { :; }
modreg()        { :; }
modunreg()      { :; }
STUBEOF

# Patch rc.pkgmanager to source the stub instead of /etc/init.d/modlibrc.
PATCHED="$TESTDIR/rc.pkgmanager"
sed "s|. /etc/init.d/modlibrc|. $STUB_MODLIBRC|g" "$RC_SCRIPT" > "$PATCHED"
chmod +x "$PATCHED"

echo "=== rc.pkgmanager tests ==="

# --- start when storage IS mounted ---
PKG_STORAGE_MOUNT="/" \
PKG_ROOT="$TESTDIR/pkgroot1" \
PROFILE_SCRIPT="$TESTDIR/profile1.sh" \
sh "$PATCHED" start

assert_file_exists "start creates pkgroot/bin when mounted" \
	"$TESTDIR/pkgroot1/bin"
assert_file_exists "start creates pkgroot/sbin when mounted" \
	"$TESTDIR/pkgroot1/sbin"
assert_file_exists "start writes PATH profile script when mounted" \
	"$TESTDIR/profile1.sh"
assert_output_contains "profile script adds pkgroot/bin to PATH" \
	"$TESTDIR/pkgroot1/bin" \
	cat "$TESTDIR/profile1.sh"

# --- stop removes profile script ---
PROFILE_SCRIPT="$TESTDIR/profile1.sh" \
PKG_ROOT="$TESTDIR/pkgroot1" \
sh "$PATCHED" stop
assert_file_absent "stop removes profile script" "$TESTDIR/profile1.sh"

# --- start when storage is NOT mounted (must exit 0, must not write profile) ---
PKG_STORAGE_MOUNT="/no/such/mount" \
PKG_ROOT="$TESTDIR/pkgroot2" \
PROFILE_SCRIPT="$TESTDIR/profile2.sh" \
sh "$PATCHED" start
rc=$?
assert_eq "start exits 0 even when storage not mounted" "0" "$rc"
assert_file_absent "start does not write profile script when storage missing" \
	"$TESTDIR/profile2.sh"

# --- status when storage mounted and pkgroot exists ---
mkdir -p "$TESTDIR/pkgroot3"
out=$(PKG_STORAGE_MOUNT="/" PKG_ROOT="$TESTDIR/pkgroot3" sh "$PATCHED" status 2>&1)
assert_eq "status prints 'running' when storage mounted and pkgroot exists" \
	"running" "$out"

# --- status when storage not mounted ---
out=$(PKG_STORAGE_MOUNT="/no/such/mount" PKG_ROOT="$TESTDIR/pkgroot4" sh "$PATCHED" status 2>&1)
assert_eq "status prints 'stopped' when storage not mounted" \
	"stopped" "$out"

summary
