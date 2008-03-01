$(call PKG_INIT_BIN, 2.0.7)
$(PKG)_SOURCE:=$(pkg)-$($(PKG)_VERSION).tar.gz
$(PKG)_SITE:=http://www.nano-editor.org/dist/v2.0
$(PKG)_BINARY:=$($(PKG)_DIR)/src/nano
$(PKG)_TARGET_BINARY:=$($(PKG)_DEST_DIR)/usr/bin/nano

$(PKG)_DEPENDS_ON := ncurses

$(PKG)_CONFIG_SUBOPTS += DS_NANO_TINY
$(PKG)_CONFIG_SUBOPTS += DS_NANO_HELP
$(PKG)_CONFIG_SUBOPTS += DS_NANO_TABCOMP
$(PKG)_CONFIG_SUBOPTS += DS_NANO_BROWSER
$(PKG)_CONFIG_SUBOPTS += DS_NANO_OPERATINGDIR
$(PKG)_CONFIG_SUBOPTS += DS_NANO_WRAPPING
$(PKG)_CONFIG_SUBOPTS += DS_NANO_JUSTIFY
$(PKG)_CONFIG_SUBOPTS += DS_NANO_MULTIBUFFER
$(PKG)_CONFIG_SUBOPTS += DS_NANO_COLOR_SYNTAX
$(PKG)_CONFIG_SUBOPTS += DS_NANO_NANORC

$(PKG)_CONFIGURE_OPTIONS += --enable-shared
$(PKG)_CONFIGURE_OPTIONS += --disable-static
$(PKG)_CONFIGURE_OPTIONS += --disable-rpath
$(PKG)_CONFIGURE_OPTIONS += --without-slang
$(PKG)_CONFIGURE_OPTIONS += --disable-utf8
$(PKG)_CONFIGURE_OPTIONS += --disable-mouse
$(PKG)_CONFIGURE_OPTIONS += --disable-speller
$(PKG)_CONFIGURE_OPTIONS += $(if $(DS_NANO_TINY),--enable-tiny)
$(PKG)_CONFIGURE_OPTIONS += $(if $(DS_NANO_HELP),,--disable-help)
$(PKG)_CONFIGURE_OPTIONS += $(if $(DS_NANO_TABCOMP),,--disable-tabcomp)
$(PKG)_CONFIGURE_OPTIONS += $(if $(DS_NANO_BROWSER),,--disable-browser)
$(PKG)_CONFIGURE_OPTIONS += $(if $(DS_NANO_OPERATINGDIR),,--disable-operatingdir)
$(PKG)_CONFIGURE_OPTIONS += $(if $(DS_NANO_WRAPPING),,--disable-wrapping)
$(PKG)_CONFIGURE_OPTIONS += $(if $(DS_NANO_JUSTIFY),,--disable-justify)
$(PKG)_CONFIGURE_OPTIONS += $(if $(DS_NANO_MULTIBUFFER),--enable-multibuffer)
$(PKG)_CONFIGURE_OPTIONS += $(if $(DS_NANO_COLOR_SYNTAX),--enable-color)
$(PKG)_CONFIGURE_OPTIONS += $(if $(DS_NANO_NANORC),--enable-nanorc)

$(PKG_SOURCE_DOWNLOAD)
$(PKG_UNPACKED)
$(PKG_CONFIGURED_CONFIGURE)

$($(PKG)_BINARY): $($(PKG)_DIR)/.configured
	PATH="$(TARGET_PATH)" \
		$(MAKE) -C $(NANO_DIR)

$($(PKG)_TARGET_BINARY): $($(PKG)_BINARY)
	mkdir -p $(NANO_DEST_DIR)/usr/share/terminfo/{v,x}
	cp $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/share/terminfo/v/{vt102,vt102-nsgr,vt102-w} \
		$(NANO_DEST_DIR)/usr/share/terminfo/v/
	cp $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/share/terminfo/x/xterm \
		$(NANO_DEST_DIR)/usr/share/terminfo/x/
	$(INSTALL_BINARY_STRIP)

$(pkg):

$(pkg)-precompiled: $($(PKG)_TARGET_BINARY)

$(pkg)-clean:
	-$(MAKE) -C $(NANO_DIR) clean
	$(RM) $(NANO_DS_CONFIG_FILE)

$(pkg)-uninstall: 
	$(RM) $(NANO_TARGET_BINARY)
	$(RM) $(NANO_DEST_DIR)/usr/share/terminfo/{v,x}

$(PKG_FINISH)
