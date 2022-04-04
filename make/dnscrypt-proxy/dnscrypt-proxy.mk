$(call PKG_INIT_BIN, 87939aad60305b59705425c2fa06f5baaeef131b)
$(PKG)_SOURCE:=$(pkg)-$($(PKG)_VERSION).tar.xz
$(PKG)_SOURCE_CHECKSUM:=X
$(PKG)_SITE:=git@https://github.com/dyne/dnscrypt-proxy.git

$(PKG)_BINARY:=$($(PKG)_DIR)/src/proxy/dnscrypt-proxy
$(PKG)_TARGET_BINARY:=$($(PKG)_DEST_DIR)/usr/bin/dnscrypt-proxy

$(PKG)_DEPENDS_ON += libsodium

$(PKG)_CONFIGURE_PRE_CMDS += ./autogen.sh;

$(PKG)_CONFIGURE_DEFOPTS := n
$(PKG)_CONFIGURE_ENV += CC="$(TARGET_CC)"
$(PKG)_CONFIGURE_ENV += CFLAGS="$(TARGET_CFLAGS)"
$(PKG)_CONFIGURE_ENV += LDFLAGS="$(TARGET_LDFLAGS)"
$(PKG)_CONFIGURE_ENV += AR="$(TARGET_AR)"
$(PKG)_CONFIGURE_ENV += RANLIB="$(TARGET_RANLIB)"
$(PKG)_CONFIGURE_ENV += NM="$(TARGET_NM)"
$(PKG)_CONFIGURE_OPTIONS += --host "$(GNU_TARGET_NAME)" --disable-largefile --prefix=/usr --enable-plugins
#$(PKG)_CONFIGURE_OPTIONS += --with-included-ltdl

$(PKG)_RESOLVERS_FILE:=$($(PKG)_DIR)/dnscrypt-resolvers.csv
$(PKG)_TARGET_RESOLVERS_FILE:=$($(PKG)_DEST_DIR)/usr/share/dnscrypt-proxy/dnscrypt-resolvers.csv

$(PKG_SOURCE_DOWNLOAD)
$(PKG_UNPACKED)
$(PKG_CONFIGURED_CONFIGURE)

$($(PKG)_BINARY): $($(PKG)_DIR)/.configured
	$(SUBMAKE) -C $(DNSCRYPT_PROXY_DIR) \
                EXTRA_CFLAGS="$(WGET_EXTRA_CFLAGS)" \
                EXTRA_LDFLAGS="$(WGET_EXTRA_LDFLAGS)" \
                EXTRA_LIBS="$(WGET_STATIC_LIBS)"

$($(PKG)_TARGET_BINARY): $($(PKG)_BINARY)
	$(INSTALL_BINARY_STRIP)

ifeq ($(strip $(FREETZ_PACKAGE_$(PKG)_RESOLVERS)),y)
$($(PKG)_TARGET_RESOLVERS_FILE): $($(PKG)_RESOLVERS_FILE)
	$(INSTALL_FILE)
else
$($(PKG)_TARGET_RESOLVERS_FILE):
endif

$(pkg):

$(pkg)-precompiled: $($(PKG)_TARGET_BINARY) $($(PKG)_TARGET_RESOLVERS_FILE)

$(pkg)-clean:
	-$(SUBMAKE) -C $(DNSCRYPT_PROXY_DIR) clean
	$(RM) $(DNSCRYPT_PROXY_DIR)/.configured

$(pkg)-uninstall:
	$(RM) $(DNSCRYPT_PROXY_TARGET_BINARY) $(DNSCRYPT_PROXY_TARGET_RESOLVERS_FILE)

$(PKG_FINISH)
