#
# runtime-pkg.mk — opt-in packaging target for Freetz-NG runtime packages
#
# Include this file at the bottom of a package's .mk to add a $(pkg)-fpkg target
# that produces a .fpkg archive suitable for runtime installation via 'pkg install'.
#
# Usage in a package makefile:
#
#   include $(MAKE_DIR)/pkgs/pkgmanager/runtime-pkg.mk
#
# The package must provide:
#   make/pkgs/<name>/files/runtime-root/
#     Files placed here are staged into the runtime archive. The directory
#     layout mirrors the package root (e.g. usr/bin/, lib/, etc/).
#
# Optional metadata overrides (placed at make/pkgs/<name>/pkg-control):
#   Description: One-line description of the package
#   Depends: comma-separated list of runtime package dependencies
#
# Output:
#   packages/runtime/<name>-<version>-<arch>.fpkg
#

RUNTIME_PKGS_OUTPUT_DIR:=$(PACKAGES_DIR_ROOT)/runtime

$(PKG)_RUNTIME_DIR:=$($(PKG)_MAKE_DIR)/files/runtime-root
$(PKG)_RUNTIME_CONTROL:=$($(PKG)_MAKE_DIR)/pkg-control
$(PKG)_FPKG_ARCH:=$(call qstrip,$(FREETZ_TARGET_ARCH_ENDIANNESS_DEPENDENT))-linux-uclibc$(call qstrip,$(FREETZ_TARGET_TRIPLET_UCLIBC_ABI))
$(PKG)_FPKG:=$(RUNTIME_PKGS_OUTPUT_DIR)/$(pkg)-$($(PKG)_VERSION)-$($(PKG)_FPKG_ARCH).fpkg

$($(PKG)_FPKG): $(wildcard $($(PKG)_RUNTIME_DIR)) $(wildcard $($(PKG)_RUNTIME_CONTROL))
	@[ -d "$($(PKG)_RUNTIME_DIR)" ] || { \
		echo "pkg-build: error: no runtime-root found for $(pkg)"; \
		echo "pkg-build:        create make/pkgs/$(pkg)/files/runtime-root/ with the files to package"; \
		exit 1; \
	}
	@mkdir -p $(RUNTIME_PKGS_OUTPUT_DIR)
	$(FREETZ_BASE_DIR)/tools/pkg-build \
		$(pkg) \
		$($(PKG)_VERSION) \
		$($(PKG)_FPKG_ARCH) \
		$($(PKG)_RUNTIME_DIR) \
		$(RUNTIME_PKGS_OUTPUT_DIR) \
		$(if $(wildcard $($(PKG)_RUNTIME_CONTROL)),--control-file $($(PKG)_RUNTIME_CONTROL))

$(pkg)-fpkg: $($(PKG)_FPKG)
.PHONY: $(pkg)-fpkg
