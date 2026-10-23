$(call PKG_INIT_BIN, 1.0.0)
$(PKG)_CATEGORY_PKGS:=Tools

$(PKG_UNPACKED)

$(pkg):

$(pkg)-precompiled:

$(pkg)-clean:

$(PKG_FINISH)

include $(MAKE_DIR)/pkgs/pkgmanager/runtime-pkg.mk
