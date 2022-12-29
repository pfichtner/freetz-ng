$(call TOOLS_INIT, 0.98)
$(PKG)_SOURCE:=fastjar-$($(PKG)_VERSION).tar.gz
$(PKG)_HASH:=f156abc5de8658f22ee8f08d7a72c88f9409ebd8c7933e9466b0842afeb2f145
$(PKG)_SITE:=http://download.savannah.nongnu.org/releases/fastjar/

$(PKG)_INSTALL_DIR := $(TOOLS_DIR)/fastjar

$(PKG)_BINARIES            := grepjar fastjar
$(PKG)_BINARIES_BUILD_DIR  := $($(PKG)_BINARIES:%=$($(PKG)_DIR)/%)
$(PKG)_BINARIES_TARGET_DIR := $($(PKG)_BINARIES:%=$($(PKG)_INSTALL_DIR)/%)

$(TOOLS_SOURCE_DOWNLOAD)
$(TOOLS_UNPACKED)
$(TOOLS_CONFIGURED_NOP)

$($(PKG)_BINARIES_BUILD_DIR): $($(PKG)_DIR)/.configured
	$(TOOLS_SUBMAKE) -C $(FASTJAR_HOST_DIR) $(FASTJAR_HOST_BINARIES)

$($(PKG)_BINARIES_TARGET_DIR): $($(PKG)_INSTALL_DIR)/%: $($(PKG)_DIR)/%
	$(INSTALL_FILE)

$(pkg)-precompiled: $($(PKG)_BINARIES_TARGET_DIR)


$(pkg)-clean:
	-$(MAKE) -C $(FASTJAR_HOST_DIR) clean

$(pkg)-dirclean:
	$(RM) -r $(FASTJAR_HOST_DIR)

$(pkg)-distclean: $(pkg)-dirclean
	$(RM) \
		$(FASTJAR_HOST_INSTALL_DIR)/grepjar \
		$(FASTJAR_HOST_INSTALL_DIR)/fastjar

$(TOOLS_FINISH)
