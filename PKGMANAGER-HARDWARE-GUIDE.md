# Freetz-NG Runtime Package Manager — Hardware Verification Guide

Step-by-step procedure for verifying the package manager works correctly on a real router.
No hardware access is assumed until Step 6; everything before that runs on the build host.

**Supported hardware (v1)**: Fritz!Box 7390, 7490, or 6490 — ARM 32-bit (`arm-linux-uclibcgnueabi`)  
**Prerequisite**: A working Freetz-NG build environment (`make precompiled` completes successfully)  
**Host requirement**: OpenSSL 3.0+ (`openssl version` must show 3.x)

---

## Phase 0 — Generate a signing keypair (once per deployment)

Do this **before** building firmware. The public key is baked into the image; you cannot update it without reflashing.

```sh
# On the build host, from the freetz-ng root
openssl genpkey -algorithm ed25519 -out repo-private.pem
openssl pkey   -in repo-private.pem -pubout \
               -out make/pkgs/pkgmanager/files/root/etc/pkgmanager/trusted.pub

# Verify
openssl pkey -in make/pkgs/pkgmanager/files/root/etc/pkgmanager/trusted.pub \
             -pubin -text -noout | head -3
```

Expected output (last line): `ED25519 Public-Key:`

> **Keep `repo-private.pem` secure.** It never goes into firmware or the router.  
> Anyone with this key can sign packages your router will install without question.

---

## Phase 1 — Configure and build firmware

### 1.1 Run menuconfig

```sh
make menuconfig
```

Enable these options (use `/` to search by name):

| Option | Path | Why |
|---|---|---|
| `FREETZ_PACKAGE_PKGMANAGER` | Packages → Tools | the pkg manager itself |
| `FREETZ_BUSYBOX___V138_SHA256SUM` | BusyBox → Coreutils | payload integrity checks |
| `FREETZ_PACKAGE_OPENSSL` | Packages → Libraries | repository signature verification |

Select your router model under **Target system** (e.g., Fritz!Box 7490).

Or edit `.config` directly and add:

```
CONFIG_FREETZ_PACKAGE_PKGMANAGER=y
CONFIG_FREETZ_BUSYBOX___V138_SHA256SUM=y
CONFIG_FREETZ_PACKAGE_OPENSSL=y
```

Then run `make oldconfig` to propagate dependencies.

### 1.2 Build

```sh
make
```

Duration: 20–60 minutes depending on the host. The finished image is at:

```
images/fritz.box.fritzos-<version>.image
```

### 1.3 Verify the image contains the package manager

```sh
# Inspect what the squashfs contains without flashing
ls make/pkgs/pkgmanager/files/root/usr/bin/pkg         # must exist
ls make/pkgs/pkgmanager/files/root/etc/pkgmanager/trusted.pub  # must exist
grep -c '^Package:' images/*.image 2>/dev/null || true # informational only
```

---

## Phase 2 — Build the hello-pkg test package

```sh
# From freetz-ng root on the build host
make hello-pkg-fpkg
```

Output:

```
packages/runtime/hello-pkg-1.0.0-arm-linux-uclibcgnueabi.fpkg
```

Inspect the archive to verify its structure:

```sh
FPKG=packages/runtime/hello-pkg-1.0.0-arm-linux-uclibcgnueabi.fpkg
tar tzf "$FPKG"
tar xzf "$FPKG" -O CONTROL/control
tar xzf "$FPKG" -O CONTROL/manifest
```

Expected `CONTROL/control`:

```
Name: hello-pkg
Version: 1.0.0
FormatVersion: 1
Arch: arm-linux-uclibcgnueabi
Description: Freetz-NG runtime package manager test package
```

---

## Phase 3 — Build and sign a repository

```sh
# On the build host
mkdir -p my-freetz-repo
cp packages/runtime/hello-pkg-1.0.0-arm-linux-uclibcgnueabi.fpkg my-freetz-repo/

tools/repo-build my-freetz-repo/ repo-private.pem \
    --arch arm-linux-uclibcgnueabi \
    --valid-days 365 \
    --sequence 1
```

Expected output:

```
repo-build: wrote 1 package(s) to my-freetz-repo/
repo-build:   Sequence=1  ValidUntil=2027-10-23
repo-build:   SHA256-Packages=<hex>
```

Verify the generated files:

```sh
ls -lh my-freetz-repo/
# Must show: Release  Release.sig  Packages  hello-pkg-1.0.0-arm-linux-uclibcgnueabi.fpkg

cat my-freetz-repo/Release
# Must show ValidUntil, Sequence, SHA256-Packages

# Verify the signature with your own public key before serving
base64 -d my-freetz-repo/Release.sig > /tmp/rel.sig
openssl pkeyutl -verify -pubin \
    -inkey make/pkgs/pkgmanager/files/root/etc/pkgmanager/trusted.pub \
    -rawin -in my-freetz-repo/Release -sigfile /tmp/rel.sig \
    && echo "Signature OK"
```

### 3.1 Serve the repository

Option A — HTTP server on the build host (router must reach host over LAN):

```sh
cd my-freetz-repo && python3 -m http.server 8080
# Note your host IP: ip addr | grep "inet " | grep -v 127
# Repository URL will be: http://<host-ip>:8080
```

Option B — Copy directly to USB drive (no network needed):

```sh
USB_MOUNT=/run/media/$USER/<your-usb-label>   # adjust to your mount point
mkdir -p "$USB_MOUNT/freetz-pkgs"
cp my-freetz-repo/* "$USB_MOUNT/freetz-pkgs/"
# Repository URL will be: file:///var/media/ftp/<label>/freetz-pkgs
```

> `file://` URLs require BusyBox wget to support the file scheme; HTTP is more reliable.

---

## Phase 4 — Flash firmware to the router

Use one of:

- **Fritz!Box web UI** (System → Update → Load firmware from local storage)
- **AVM Recovery tool** (holds CTL during boot, then push image via browser at 192.168.178.1)

After flashing, the router reboots. Wait for it to come back up (~2 minutes).

Verify the new firmware is running:

```sh
# SSH or telnet to the router (if enabled by your Freetz-NG build)
ssh root@192.168.178.1
pkg help
# Must print the pkg usage text
```

---

## Phase 5 — Prepare USB storage on the router

### 5.1 Prepare the USB drive (on the host, before inserting into router)

```sh
# Identify the drive carefully — wrong device destroys data
lsblk
sudo mkfs.ext4 -L freetz /dev/sdX   # replace sdX with the correct device
```

### 5.2 Identify the mount point on the router

Insert the USB drive. Freetz-NG mounts it automatically.

```sh
# On the router
cat /proc/mounts | grep "/var/media/ftp"
# Example output:
#   /dev/sda1 /var/media/ftp/uStor01 ext4 rw,...
```

The mount point (e.g., `/var/media/ftp/uStor01`) is your `PKG_STORAGE_MOUNT`.

If no entry appears after 30 seconds, check:

```sh
dmesg | tail -20          # look for USB storage messages
ls /var/media/ftp/        # should show the label
```

---

## Phase 6 — Configure the package manager on the router

Edit the config file (persists across reboots in TFFS):

```sh
# On the router
vi /mod/etc/conf/pkgmanager.cfg
```

Set:

```sh
export PKG_ROOT='/var/media/ftp/uStor01/pkgroot'     # adjust label
export PKG_STORAGE_MOUNT='/var/media/ftp/uStor01'    # adjust label
export PKG_ARCH='arm-linux-uclibcgnueabi'
export PKG_REPO_URL='http://192.168.178.100:8080'    # your host IP and port
export PKG_PUBKEY_FILE='/etc/pkgmanager/trusted.pub'
export PKG_DOWNLOAD_TIMEOUT='30'
```

Verify the config is loaded:

```sh
pkg status
```

Expected output (storage mounted, repo not yet cached):

```
Freetz-NG Runtime Package Manager 1.0
Package root  : /var/media/ftp/uStor01/pkgroot
Storage mount : /var/media/ftp/uStor01
Storage state : mounted
Database      : not initialised
Target arch   : arm-linux-uclibcgnueabi
Repository    : http://192.168.178.100:8080
Repo index    : not cached (run 'pkg update')
Trust anchor  : /etc/pkgmanager/trusted.pub
```

---

## Phase 7 — Update repository index

```sh
# On the router (HTTP server must be running on host)
pkg update
```

Expected output:

```
pkg: fetching repository index from http://192.168.178.100:8080...
pkg: repository index updated (1 package(s), valid until 2027-10-23)
```

Verify the cached index:

```sh
cat /var/media/ftp/uStor01/pkgroot/cache/Release
cat /var/media/ftp/uStor01/pkgroot/cache/Packages
cat /var/media/ftp/uStor01/pkgroot/cache/repo-sequence   # must contain: 1
```

If `pkg update` fails:

```sh
# Check reachability
wget -q -O - http://192.168.178.100:8080/Release | head -5

# Check trust anchor
ls -la /etc/pkgmanager/trusted.pub

# Check openssl
openssl version   # must be 3.x
```

---

## Phase 8 — Install the test package

```sh
# On the router
pkg install hello-pkg
```

Expected output:

```
pkg: downloading hello-pkg 1.0.0...
pkg: installed hello-pkg 1.0.0
```

Verify the installation:

```sh
pkg list
# Name                     Version
# ------------------------ -------
# hello-pkg                1.0.0

pkg info hello-pkg
# Name: hello-pkg
# Version: 1.0.0
# ...
# Installed-Files:
# <hash>  ./usr/bin/hello

ls -la /var/media/ftp/uStor01/pkgroot/usr/bin/hello
# -rwxr-xr-x ...

/var/media/ftp/uStor01/pkgroot/usr/bin/hello
# Hello from Freetz-NG runtime package manager!
```

---

## Phase 9 — Verify across reboot

```sh
# On the router
reboot
```

After the router comes back up:

```sh
ssh root@192.168.178.1
pkg status
# Storage state : mounted   (USB must remount automatically)
# Database      : ok (1 package(s) installed)

pkg list
# hello-pkg  1.0.0   ← must still be listed

/var/media/ftp/uStor01/pkgroot/usr/bin/hello
# Hello from Freetz-NG runtime package manager!
```

If the USB does not remount automatically, check `/mod/etc/conf/mod.cfg` for `MOD_EXTERNAL_DIRECTORY` and USB storage settings.

---

## Phase 10 — Remove the package

```sh
pkg remove hello-pkg
# pkg: removed hello-pkg 1.0.0

pkg list
# No packages installed.

ls /var/media/ftp/uStor01/pkgroot/usr/bin/hello
# ls: cannot access ...: No such file or directory
```

Only files that belonged to `hello-pkg` are removed. Nothing outside `pkgroot/` is touched.

---

## Phase 11 — Rejection tests (optional but recommended)

### Wrong architecture

```sh
# On the host — build a package for a wrong arch
tools/pkg-build hello-pkg 1.0.0 x86_64-linux-gnu \
    make/pkgs/hello-pkg/files/runtime-root /tmp

# Copy to router and attempt install
scp /tmp/hello-pkg-1.0.0-x86_64-linux-gnu.fpkg root@192.168.178.1:/tmp/
ssh root@192.168.178.1 'pkg install /tmp/hello-pkg-1.0.0-x86_64-linux-gnu.fpkg'
# Expected: pkg: rejected: incompatible architecture x86_64-linux-gnu ...
```

### Tampered archive

```sh
# On the router
cp /var/media/ftp/uStor01/pkgroot/cache/hello-pkg-1.0.0-arm-linux-uclibcgnueabi.fpkg \
   /tmp/tampered.fpkg
printf 'TAMPERED' >> /tmp/tampered.fpkg
pkg install /tmp/tampered.fpkg
# Expected: pkg: rejected: digest verification failed
```

### Repository rollback

Update the repository with `--sequence 0` (lower than cached `1`):

```sh
# On the host
tools/repo-build my-freetz-repo/ repo-private.pem \
    --arch arm-linux-uclibcgnueabi --valid-days 365 --sequence 0

# On the router
pkg update
# Expected: pkg: sequence rollback detected (cached=1 incoming=0) — rejected
```

---

## Acceptance checklist (maps to PRD section 13)

| # | Test | Expected |
|---|---|---|
| 1 | Clean firmware build with pkgmanager disabled | Router boots normally ✓ |
| 2 | `make hello-pkg-fpkg` | `.fpkg` produced ✓ |
| 3 | `pkg install hello-pkg` | `hello` binary runs ✓ |
| 4 | `pkg list` after install | Shows `hello-pkg 1.0.0` ✓ |
| 5 | `pkg list` after reboot | Still shows `hello-pkg 1.0.0` ✓ |
| 6 | `pkg remove hello-pkg` | Only owned files removed ✓ |
| 7 | Install with USB unplugged | Fails, no DB created ✓ |
| 8 | Wrong-arch `.fpkg` | Rejected before payload ✓ |
| 9 | Tampered archive | Rejected before extraction ✓ |
| 10 | Tampered `Release` (bad signature) | `pkg update` rejected ✓ |
| 11 | Expired `Release` | `pkg update` rejected ✓ |
| 12 | Sequence rollback | `pkg update` rejected ✓ |
| 13 | `Packages` hash mismatch | `pkg update` rejected ✓ |

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `pkg: storage not available` | USB not mounted | Insert USB; check `cat /proc/mounts` |
| `pkg update` fails with no output | wget can't reach host | Check IP, firewall, `wget http://host:8080/Release` |
| `signature verification failed` | Wrong `trusted.pub` or old firmware | Rebuild firmware with correct key; re-flash |
| `pkg: openssl: command not found` | `FREETZ_PACKAGE_OPENSSL` not enabled | Rebuild firmware with openssl enabled |
| `sha256sum: not found` | `FREETZ_BUSYBOX___V138_SHA256SUM` not enabled | Rebuild firmware |
| Mount point is not `uStor01` | Different USB label | Check `cat /proc/mounts`; adjust `pkgmanager.cfg` |
| Package survives remove | Bug — should not happen | File a bug with `pkg info <name>` output |

---

## Log locations

| File | Contents |
|---|---|
| `/var/log/mod_mount.log` | USB mount/unmount events |
| `/var/log/external.log` | `rc.external` package loader events |
| `<pkgroot>/database/transactions/` | Transaction journals (present = interrupted operation) |
| `/tmp/pkg.XXXXXX` (if present) | Leftover temp dir from crashed install |

Recover from an interrupted install:

```sh
ls /var/media/ftp/uStor01/pkgroot/database/transactions/
# hello-pkg.in-progress  ← stale journal from a crash
pkg remove hello-pkg    # reads manifest, removes what was installed
# or, if the package entry is incomplete:
rm /var/media/ftp/uStor01/pkgroot/database/transactions/hello-pkg.in-progress
```
