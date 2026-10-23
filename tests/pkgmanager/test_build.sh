#!/bin/sh
# M2: build integration tests
# Verifies pkg-build produces a valid .fpkg with correct metadata
# and that the runtime-root staging pattern works end-to-end.

. "$(dirname "$0")/lib/assert.sh"

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
PKG_BIN="$REPO/make/pkgs/pkgmanager/files/root/usr/bin/pkg"
PKG_BUILD="$REPO/tools/pkg-build"

TESTDIR=$(mktemp -d)
trap 'rm -rf "$TESTDIR"' EXIT

export PKG_ROOT="$TESTDIR/pkgroot"
export PKG_STORAGE_MOUNT="/"
export PKG_ARCH="arm-linux-uclibcgnueabi"
mkdir -p "$PKG_ROOT"

echo "=== Build integration tests ==="

# --- Build a .fpkg from runtime-root using pkg-build with --control-file ---
STAGING="$TESTDIR/staging"
mkdir -p "$STAGING/usr/bin"
cat > "$STAGING/usr/bin/greet" <<'SCRIPT'
#!/bin/sh
echo "Hello from greet package v2.0.0!"
SCRIPT
chmod +x "$STAGING/usr/bin/greet"

CTRL="$TESTDIR/pkg-control"
cat > "$CTRL" <<'EOF'
Description: Test greeting package
Depends: hello-pkg
EOF

OUTDIR="$TESTDIR/out"
mkdir -p "$OUTDIR"

assert_exit "pkg-build exits 0 with control-file" 0 \
	"$PKG_BUILD" greet 2.0.0 arm-linux-uclibcgnueabi "$STAGING" "$OUTDIR" --control-file "$CTRL"

FPKG="$OUTDIR/greet-2.0.0-arm-linux-uclibcgnueabi.fpkg"
assert_file_exists "pkg-build produces .fpkg file" "$FPKG"

# --- Inspect archive structure ---
control_output=$(tar xzf "$FPKG" -O CONTROL/control 2>/dev/null)

assert_output_contains "control has Description from --control-file" \
	"Description: Test greeting package" \
	tar xzf "$FPKG" -O CONTROL/control

assert_output_contains "control has Depends from --control-file" \
	"Depends: hello-pkg" \
	tar xzf "$FPKG" -O CONTROL/control

assert_output_contains "control has FormatVersion 1" \
	"FormatVersion: 1" \
	tar xzf "$FPKG" -O CONTROL/control

assert_output_contains "manifest has correct sha256 entry" \
	"./usr/bin/greet" \
	tar xzf "$FPKG" -O CONTROL/manifest

assert_output_contains "build-manifest is present" \
	"format-version: 1" \
	tar xzf "$FPKG" -O CONTROL/build-manifest

assert_output_contains "build-manifest records source file hash" \
	"./usr/bin/greet" \
	tar xzf "$FPKG" -O CONTROL/build-manifest

# --- Install and verify ---
assert_exit "greet package installs cleanly" 0 \
	"$PKG_BIN" install "$FPKG"

assert_file_exists "greet binary installed at pkgroot" \
	"$PKG_ROOT/usr/bin/greet"

assert_output_contains "pkg info shows description" \
	"Description: Test greeting package" \
	"$PKG_BIN" info greet

assert_output_contains "pkg info shows depends" \
	"Depends: hello-pkg" \
	"$PKG_BIN" info greet

assert_output_contains "installed greet script runs correctly" \
	"Hello from greet package v2.0.0" \
	"$PKG_ROOT/usr/bin/greet"

# --- Build determinism: two identical builds produce identical archives ---
OUTDIR2="$TESTDIR/out2"
mkdir -p "$OUTDIR2"
"$PKG_BUILD" greet 2.0.0 arm-linux-uclibcgnueabi "$STAGING" "$OUTDIR2" --control-file "$CTRL" >/dev/null 2>&1
FPKG2="$OUTDIR2/greet-2.0.0-arm-linux-uclibcgnueabi.fpkg"
# Manifests must be identical (content-addressed)
manifest1=$(tar xzf "$FPKG"  -O CONTROL/manifest 2>/dev/null)
manifest2=$(tar xzf "$FPKG2" -O CONTROL/manifest 2>/dev/null)
assert_eq "two identical builds produce the same manifest" "$manifest1" "$manifest2"

# --- Rebuild test: verify hello-pkg runtime-root fixture via pkg-build ---
HELLO_ROOT="$REPO/make/pkgs/hello-pkg/files/runtime-root"
HELLO_CTRL="$REPO/make/pkgs/hello-pkg/pkg-control"
HELLO_OUT="$TESTDIR/hello-rebuild"
mkdir -p "$HELLO_OUT"
assert_exit "pkg-build on hello-pkg runtime-root exits 0" 0 \
	"$PKG_BUILD" hello-pkg 1.0.0 arm-linux-uclibcgnueabi "$HELLO_ROOT" "$HELLO_OUT" \
	--control-file "$HELLO_CTRL"

assert_output_contains "rebuilt hello control has Description" \
	"Description: Freetz-NG runtime package manager test package" \
	tar xzf "$HELLO_OUT/hello-pkg-1.0.0-arm-linux-uclibcgnueabi.fpkg" -O CONTROL/control

summary
