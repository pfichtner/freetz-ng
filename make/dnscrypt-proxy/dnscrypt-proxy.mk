$(call PKG_INIT_BIN, 87939aad60305b59705425c2fa06f5baaeef131b)
$(PKG)_SOURCE:=$(pkg)-$($(PKG)_VERSION).tar.xz
$(PKG)_SOURCE_CHECKSUM:=X
$(PKG)_SITE:=git@https://github.com/dyne/dnscrypt-proxy.git

$(PKG)_BINARY:=$($(PKG)_DIR)/src/proxy/dnscrypt-proxy
$(PKG)_TARGET_BINARY:=$($(PKG)_DEST_DIR)/usr/bin/dnscrypt-proxy

$(PKG)_DEPENDS_ON += libsodium

$(PKG)_CONFIGURE_PRE_CMDS += $(AUTORECONF)
$(PKG)_CONFIGURE_PRE_CMDS += $(call PKG_PREVENT_RPATH_HARDCODING,./configure)

$(PKG)_CONFIGURE_OPTIONS += --disable-rpath
$(PKG)_CONFIGURE_OPTIONS += --host "$(GNU_TARGET_NAME)"
$(PKG)_CONFIGURE_OPTIONS += --disable-largefile
$(PKG)_CONFIGURE_OPTIONS += --prefix=/usr
$(PKG)_CONFIGURE_OPTIONS += --enable-plugins
#$(PKG)_CONFIGURE_OPTIONS += --with-included-ltdl

$(PKG)_RESOLVERS_FILE:=$($(PKG)_DIR)/dnscrypt-resolvers.csv
$(PKG)_TARGET_RESOLVERS_FILE:=$($(PKG)_DEST_DIR)/var/media/ftp/dnscrypt-resolvers.csv

$(PKG_SOURCE_DOWNLOAD)
$(PKG_UNPACKED)
$(PKG_CONFIGURED_CONFIGURE)


$($(PKG)_BINARY): $($(PKG)_DIR)/.configured
	$(SUBMAKE) -C $(DNSCRYPT_PROXY_DIR)

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
