# Freetz-NG Runtime Package Manager — Setup and Usage

## Requirements

- Freetz-NG firmware with `FREETZ_PACKAGE_PKGMANAGER=y` enabled at build time.
- USB storage device mounted at the configured path (default: `/var/media/ftp/uStor01`).
- First supported target: ARM 32-bit (`arm-linux-uclibcgnueabi`) — Fritz!Box 7390, 7490, 6490.

## Initial Setup

The package manager is bootstrapped by the Freetz-NG firmware. No manual installation is required on the router. On first boot with USB storage present, the package root directory is created automatically.

The package root defaults to `<usb-mount>/pkgroot/`. Change it in `/mod/etc/conf/pkgmanager.cfg`:

```sh
export PKG_ROOT='/var/media/ftp/uStor01/pkgroot'
export PKG_STORAGE_MOUNT='/var/media/ftp/uStor01'
export PKG_ARCH='arm-linux-uclibcgnueabi'
```

## Installing a Package

```sh
pkg install /var/media/ftp/uStor01/cache/tcpdump-4.99.4-arm-linux-uclibcgnueabi.fpkg
```

The manager verifies the archive structure, architecture compatibility, and payload digests before writing any files. If verification fails, nothing is installed.

## Listing Installed Packages

```sh
pkg list
```

## Showing Package Details

```sh
pkg info tcpdump
```

## Removing a Package

```sh
pkg remove tcpdump
```

Only files recorded in the package's own manifest are removed. Files owned by other packages or the firmware are never touched.

## Checking Status

```sh
pkg status
```

Shows the manager version, configured package root, storage mount state, and database health.

## Building a Runtime Package

### Option 1: Using the make target (recommended for Freetz-NG packages)

In your package makefile, include `runtime-pkg.mk` at the bottom and define a `files/runtime-root/` directory:

```makefile
# at the bottom of make/pkgs/mypkg/mypkg.mk
include $(MAKE_DIR)/pkgs/pkgmanager/runtime-pkg.mk
```

Place runtime files under `make/pkgs/mypkg/files/runtime-root/` and optional metadata in `make/pkgs/mypkg/pkg-control`:

```
Description: My package for runtime installation
Depends: libfoo
```

Build the .fpkg:

```sh
make mypkg-fpkg
```

The archive is written to `packages/runtime/<name>-<version>-<arch>.fpkg`.

### Option 2: Using pkg-build directly

```sh
tools/pkg-build <name> <version> <arch> <stagingroot> <destdir>
# optional control override:
tools/pkg-build <name> <version> <arch> <stagingroot> <destdir> --control-file <pkg-control>
```

## Recovery

If the router loses power during an install or remove operation, a transaction journal is left at `<pkgroot>/database/transactions/<name>.in-progress`. On the next `pkg` invocation, check for and recover from interrupted operations:

```sh
pkg status   # reports journal state
```

To recover manually: if a `.in-progress` journal exists, the package is partially installed. Remove it with `pkg remove <name>` (which reads the manifest to remove only installed files) or delete the journal and database record if the package is not usable.

## Known Limitations (v1)

- One supported target: ARM 32-bit (`arm-linux-uclibcgnueabi`).
- `pkg install` accepts local `.fpkg` files only. Repository client (M3) is not yet implemented.
- Dependency resolution is recorded but not enforced (M4).
- No package lifecycle hooks (deferred).
- USB storage is the only supported backend; USB naming varies by router model and configuration.
