#!/bin/sh
# M3: repository trust tests
# Uses a fake-wget that reads from a local directory, and a test Ed25519 keypair
# generated at test time. Requires openssl 1.1.1+ with Ed25519 support.

. "$(dirname "$0")/lib/assert.sh"

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
PKG_BIN="$REPO/make/pkgs/pkgmanager/files/root/usr/bin/pkg"
PKG_BUILD="$REPO/tools/pkg-build"
REPO_BUILD="$REPO/tools/repo-build"

TESTDIR=$(mktemp -d)
trap 'rm -rf "$TESTDIR"' EXIT

echo "=== Repository trust tests ==="

# --- Prerequisite: Ed25519 support ---
if ! openssl genpkey -algorithm ed25519 -out /dev/null 2>/dev/null; then
	echo "  SKIP: openssl does not support Ed25519 (requires >= 1.1.1)"
	echo "Results: 0 passed, 0 failed (skipped)"
	exit 0
fi

# Generate test keypair
PRIVKEY="$TESTDIR/repo-private.pem"
PUBKEY="$TESTDIR/trusted.pub"
openssl genpkey -algorithm ed25519 -out "$PRIVKEY" 2>/dev/null
openssl pkey -in "$PRIVKEY" -pubout -out "$PUBKEY" 2>/dev/null

# Build a hello-pkg .fpkg to populate the repository
REPO_DIR="$TESTDIR/repo"
mkdir -p "$REPO_DIR"
"$PKG_BUILD" hello-pkg 1.0.0 arm-linux-uclibcgnueabi \
	"$REPO/make/pkgs/hello-pkg/files/runtime-root" "$REPO_DIR" \
	--control-file "$REPO/make/pkgs/hello-pkg/pkg-control" >/dev/null

# Generate a signed repository index
"$REPO_BUILD" "$REPO_DIR" "$PRIVKEY" \
	--arch arm-linux-uclibcgnueabi --valid-days 365 --sequence 1 >/dev/null

# --- Set up fake wget: maps URL to files in REPO_DIR ---
FAKE_BIN="$TESTDIR/fake-bin"
mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/wget" <<WGETEOF
#!/bin/sh
# Fake wget for testing — copies from REPO_DIR based on URL basename
outfile=""
while [ \$# -gt 0 ]; do
    case "\$1" in
        -O) shift; outfile="\$1" ;;
        -q|-T) shift ;;
        http://*|https://*|file://*) url="\$1" ;;
        *) ;;
    esac
    shift
done
filename="\${url##*/}"
src="\$REPO_DIR/\$filename"
[ -f "\$src" ] || { echo "fake-wget: not found: \$src" >&2; exit 1; }
cp "\$src" "\$outfile"
WGETEOF
chmod +x "$FAKE_BIN/wget"
export REPO_DIR

# pkg configuration for tests
export PKG_ROOT="$TESTDIR/pkgroot"
export PKG_STORAGE_MOUNT="/"
export PKG_ARCH="arm-linux-uclibcgnueabi"
export PKG_REPO_URL="https://fake-test-repo.local/arm"
export PKG_PUBKEY_FILE="$PUBKEY"
export PKG_DOWNLOAD_TIMEOUT="10"
mkdir -p "$PKG_ROOT"

# Prepend fake-bin to PATH so pkg uses our fake wget
export PATH="$FAKE_BIN:$PATH"

# ---------------------------------------------------------------------------
# Test 1: pkg update with valid signed repository succeeds
# ---------------------------------------------------------------------------
assert_exit "pkg update succeeds with valid signature" 0 \
	"$PKG_BIN" update

assert_file_exists "Release cached after update" \
	"$PKG_ROOT/cache/Release"
assert_file_exists "Packages cached after update" \
	"$PKG_ROOT/cache/Packages"
assert_file_exists "sequence number cached" \
	"$PKG_ROOT/cache/repo-sequence"
assert_output_contains "cached sequence is 1" "1" \
	cat "$PKG_ROOT/cache/repo-sequence"

assert_output_contains "pkg status shows repo index ok" \
	"Repo index    : ok" \
	"$PKG_BIN" status

# ---------------------------------------------------------------------------
# Test 2: pkg update rejects a tampered Release (bad signature)
# ---------------------------------------------------------------------------
# Save good cache, then serve a modified Release
cp "$REPO_DIR/Release" "$TESTDIR/Release.good"
printf '\nTAMPERED: yes\n' >> "$REPO_DIR/Release"

assert_exit "pkg update rejects tampered Release (exit 4)" 4 \
	"$PKG_BIN" update

# Restore good Release
cp "$TESTDIR/Release.good" "$REPO_DIR/Release"

# Cached index must be the last valid one, not the tampered one
assert_file_absent "tampered Release not committed to cache" \
	"$PKG_ROOT/cache/Release.corrupted"

# ---------------------------------------------------------------------------
# Test 3: pkg update rejects expired metadata
# ---------------------------------------------------------------------------
# Build a repository with a past ValidUntil date
EXPIRED_DIR="$TESTDIR/expired-repo"
mkdir -p "$EXPIRED_DIR"
cp "$REPO_DIR"/*.fpkg "$EXPIRED_DIR/"
"$REPO_BUILD" "$EXPIRED_DIR" "$PRIVKEY" \
	--arch arm-linux-uclibcgnueabi --valid-days 365 --sequence 2 >/dev/null
# Patch ValidUntil to a past date
sed -i 's/ValidUntil: .*/ValidUntil: 2000-01-01/' "$EXPIRED_DIR/Release"
# Re-sign the modified Release
SIG_BIN="$TESTDIR/sig.bin"
openssl pkeyutl -sign -inkey "$PRIVKEY" -rawin -in "$EXPIRED_DIR/Release" -out "$SIG_BIN" 2>/dev/null
base64 "$SIG_BIN" > "$EXPIRED_DIR/Release.sig"

export REPO_DIR="$EXPIRED_DIR"
assert_exit "pkg update rejects expired metadata (exit 4)" 4 \
	"$PKG_BIN" update
export REPO_DIR="$TESTDIR/repo"

# ---------------------------------------------------------------------------
# Test 4: pkg update rejects sequence rollback
# ---------------------------------------------------------------------------
# Cache says sequence=1; serve sequence=0
ROLLBACK_DIR="$TESTDIR/rollback-repo"
mkdir -p "$ROLLBACK_DIR"
cp "$REPO_DIR"/*.fpkg "$ROLLBACK_DIR/"
"$REPO_BUILD" "$ROLLBACK_DIR" "$PRIVKEY" \
	--arch arm-linux-uclibcgnueabi --valid-days 365 --sequence 0 >/dev/null

export REPO_DIR="$ROLLBACK_DIR"
assert_exit "pkg update rejects sequence rollback (exit 4)" 4 \
	"$PKG_BIN" update
export REPO_DIR="$TESTDIR/repo"

# ---------------------------------------------------------------------------
# Test 5: pkg update rejects tampered Packages (hash mismatch)
# ---------------------------------------------------------------------------
cp "$REPO_DIR/Packages" "$TESTDIR/Packages.good"
printf '\nINJECTED: evil\n' >> "$REPO_DIR/Packages"

assert_exit "pkg update rejects Packages hash mismatch (exit 4)" 4 \
	"$PKG_BIN" update

cp "$TESTDIR/Packages.good" "$REPO_DIR/Packages"

# ---------------------------------------------------------------------------
# Test 6: pkg update rejects wrong public key
# ---------------------------------------------------------------------------
WRONGKEY="$TESTDIR/wrong.pub"
openssl genpkey -algorithm ed25519 2>/dev/null | \
	openssl pkey -pubout -out "$WRONGKEY" 2>/dev/null

export PKG_PUBKEY_FILE="$WRONGKEY"
assert_exit "pkg update rejects Release signed with different key (exit 4)" 4 \
	"$PKG_BIN" update
export PKG_PUBKEY_FILE="$PUBKEY"

# ---------------------------------------------------------------------------
# Test 7: pkg install <name> from repository
# ---------------------------------------------------------------------------
assert_exit "pkg install hello-pkg from repo succeeds" 0 \
	"$PKG_BIN" install hello-pkg

assert_file_exists "repo install: payload present at pkgroot" \
	"$PKG_ROOT/usr/bin/hello"

assert_output_contains "repo install: pkg list shows hello-pkg" "hello-pkg" \
	"$PKG_BIN" list

# ---------------------------------------------------------------------------
# Test 8: pkg install from repo rejects tampered archive (digest mismatch)
# ---------------------------------------------------------------------------
# Tamper the cached .fpkg
FPKG="$REPO_DIR/hello-pkg-1.0.0-arm-linux-uclibcgnueabi.fpkg"
cp "$FPKG" "$TESTDIR/hello-pkg.good"
printf 'TAMPERED' >> "$REPO_DIR/hello-pkg-1.0.0-arm-linux-uclibcgnueabi.fpkg"

# Remove the installed package first so we can re-try install
"$PKG_BIN" remove hello-pkg >/dev/null 2>&1 || true

assert_exit "repo install rejects tampered archive (exit 4)" 4 \
	"$PKG_BIN" install hello-pkg

assert_file_absent "tampered archive: no payload written" \
	"$PKG_ROOT/usr/bin/hello"

cp "$TESTDIR/hello-pkg.good" "$REPO_DIR/hello-pkg-1.0.0-arm-linux-uclibcgnueabi.fpkg"

# ---------------------------------------------------------------------------
# Test 9: pkg install <name> without cached index → clear error
# ---------------------------------------------------------------------------
# Remove the cached index
rm -f "$PKG_ROOT/cache/Packages" "$PKG_ROOT/cache/Release"
assert_exit "pkg install without index exits 3" 3 \
	"$PKG_BIN" install hello-pkg

summary
