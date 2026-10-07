$(call PKG_INIT_BIN, $(if $(FREETZ_PACKAGE_SER2NET_ABANDON),3.5.4,4.6.8))
$(PKG)_SOURCE:=$(pkg)-$($(PKG)_VERSION).tar.gz
$(PKG)_HASH_ABANDON:=ff44cc792e43e57fd3392faee3e52c82002a2aaa4a79e255667cfcd6cd64580f
$(PKG)_HASH_CURRENT:=e651adcc4cc0d0ceaa36e5997dab9ea7f8aea732b4c87ba6018d2dcc88fbe8e3
$(PKG)_HASH:=$($(PKG)_HASH_$(if $(FREETZ_PACKAGE_SER2NET_ABANDON),ABANDON,CURRENT))
$(PKG)_SITE:=@SF/ser2net
### WEBSITE:=https://ser2net.sourceforge.net/
### MANPAGE:=https://linux.die.net/man/8/ser2net
### CHANGES:=https://sourceforge.net/p/ser2net/news/
### CVSREPO:=https://sourceforge.net/projects/ser2net/

$(PKG)_BINARY:=$($(PKG)_DIR)/ser2net
$(PKG)_TARGET_BINARY:=$($(PKG)_DEST_DIR)/usr/sbin/ser2net

# Version-specific dependencies
ifeq ($(FREETZ_PACKAGE_SER2NET_CURRENT),y)
$(PKG)_DEPENDS_ON += gensio
$(PKG)_DEPENDS_ON += yaml
endif

# Conditional patches
$(PKG)_CONDITIONAL_PATCHES+=$(if $(FREETZ_PACKAGE_SER2NET_ABANDON),abandon,current)

# Version-specific configure options
ifeq ($(FREETZ_PACKAGE_SER2NET_ABANDON),y)
$(PKG)_CONFIGURE_OPTIONS += --with-pthreads=no
$(PKG)_CONFIGURE_OPTIONS += --with-openipmi=no
else
$(PKG)_CONFIGURE_OPTIONS += --with-pam=no
endif

$(PKG)_REBUILD_SUBOPTS += FREETZ_PACKAGE_SER2NET_ABANDON

$(PKG_SOURCE_DOWNLOAD)
$(PKG_UNPACKED)
$(PKG_CONFIGURED_CONFIGURE)

$($(PKG)_BINARY): $($(PKG)_DIR)/.configured
	$(SUBMAKE) -C $(SER2NET_DIR) SUBDIRS=

$($(PKG)_TARGET_BINARY): $($(PKG)_BINARY)
	$(INSTALL_BINARY_STRIP)

$(pkg):

$(pkg)-precompiled: $($(PKG)_TARGET_BINARY)


$(pkg)-clean:
	-$(SUBMAKE) -C $(SER2NET_DIR) clean

$(pkg)-uninstall:
	$(RM) $(SER2NET_TARGET_BINARY)

$(PKG_FINISH)
