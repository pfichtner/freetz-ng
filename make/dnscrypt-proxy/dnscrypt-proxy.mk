$(call PKG_INIT_BIN, 2.1.1)
$(PKG)_SOURCE:=$(pkg)-linux_mips-$($(PKG)_VERSION).tar.gz
$(PKG)_SOURCE_SHA256:=1a6af9af9929e150c08cc5672ddee43e858fbc2d68f23f47518899fc5675b619
$(PKG)_SITE:=https://github.com/DNSCrypt/$(pkg)/releases/download/$($(PKG)_VERSION)

$(PKG)_BINARY:=$($(PKG)_DIR)/dnscrypt-proxy
$(PKG)_TARGET_BINARY:=$($(PKG)_DEST_DIR)/usr/bin/dnscrypt-proxy

$(PKG_SOURCE_DOWNLOAD)
$(PKG_UNPACKED)
$(PKG_CONFIGURED_NOP)

$($(PKG)_BINARY): $($(PKG)_DIR)/.configured

$($(PKG)_TARGET_BINARY): $($(PKG)_BINARY)
	$(INSTALL_FILE)

$(pkg):

$(pkg)-precompiled: $($(PKG)_TARGET_BINARY)

$(pkg)-clean:

$(pkg)-uninstall:
	$(RM) $(DEHYDRATED_TARGET_BINARY)

$(PKG_FINISH)
