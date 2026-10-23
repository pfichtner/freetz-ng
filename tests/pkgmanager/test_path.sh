#!/bin/sh
# FR-010: path traversal and absolute paths in archives must be rejected

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

echo "=== Path traversal tests ==="

# --- crafted path-traversal archive ---
assert_exit "path-traversal archive rejected (exit 4)" 4 \
	"$PKG" install "$FIXTURES/path-traversal.fpkg"

assert_file_absent "no file written outside pkgroot" \
	"$TESTDIR/pkgroot/../../etc/injected"

assert_file_absent "no payload written for traversal archive" \
	"$PKG_ROOT/usr/bin/hello"

assert_file_absent "no database record for traversal archive" \
	"$PKG_ROOT/database/installed/evil"

# --- archive with absolute path entry ---
TMPDIR_ABS=$(mktemp -d)
trap 'rm -rf "$TMPDIR_ABS" "$TESTDIR"' EXIT
mkdir -p "$TMPDIR_ABS/CONTROL" "$TMPDIR_ABS/data"
printf 'Name: abstest\nVersion: 1.0\nFormatVersion: 1\nArch: arm-linux-uclibcgnueabi\n' \
	> "$TMPDIR_ABS/CONTROL/control"
printf '' > "$TMPDIR_ABS/CONTROL/manifest"
# Craft an archive with an absolute path using Python
python3 -c "
import tarfile, io, gzip
out = '$TESTDIR/abs-path.fpkg'
with open(out, 'wb') as buf:
    with gzip.GzipFile(fileobj=buf, mode='wb', mtime=0) as gz:
        with tarfile.open(fileobj=gz, mode='w|') as tf:
            tf.add('$TMPDIR_ABS/CONTROL/control', arcname='CONTROL/control')
            tf.add('$TMPDIR_ABS/CONTROL/manifest', arcname='CONTROL/manifest')
            info = tarfile.TarInfo(name='/etc/passwd_injected')
            content = b'root:0:0:root:/root:/bin/sh\n'
            info.size = len(content)
            tf.addfile(info, io.BytesIO(content))
"
rm -rf "$TMPDIR_ABS"

assert_exit "absolute-path archive rejected (exit 4)" 4 \
	"$PKG" install "$TESTDIR/abs-path.fpkg"

assert_file_absent "no file written at absolute path" \
	"/etc/passwd_injected"

summary
