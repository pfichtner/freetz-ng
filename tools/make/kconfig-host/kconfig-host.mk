KCONFIG_HOST_VERSION:=v5.17
KCONFIG_HOST_SOURCE:=kconfig-$(KCONFIG_HOST_VERSION).tar.xz
KCONFIG_HOST_SOURCE_SHA256:=152b350cbcfbec4586098be0647eb350fbd3c7e27e4bae153c66c19c07329379
KCONFIG_HOST_SITE:=git_archive@git://repo.or.cz/linux.git,scripts/basic,scripts/kconfig,scripts/Kbuild.include,scripts/Makefile.compiler,scripts/Makefile.build,scripts/Makefile.host,scripts/Makefile.lib,Documentation/kbuild/kconfig-language.rst,Documentation/kbuild/kconfig-macro-language.rst,Documentation/kbuild/kconfig.rst
KCONFIG_HOST_DIR:=$(TOOLS_SOURCE_DIR)/kconfig-$(KCONFIG_HOST_VERSION)
KCONFIG_HOST_MAKE_DIR:=$(TOOLS_DIR)/make/kconfig-host
KCONFIG_HOST_TARGET_DIR:=$(TOOLS_DIR)/config
KCONFIG_HOST_BUILD_PREREQ:=bison flex


kconfig-host-source: $(DL_DIR)/$(KCONFIG_HOST_SOURCE)
$(DL_DIR)/$(KCONFIG_HOST_SOURCE): | $(DL_DIR)
	$(DL_TOOL) $(DL_DIR) $(KCONFIG_HOST_SOURCE) $(KCONFIG_HOST_SITE) $(KCONFIG_HOST_SOURCE_SHA256)

kconfig-host-unpacked: $(KCONFIG_HOST_DIR)/.unpacked
$(KCONFIG_HOST_DIR)/.unpacked: $(DL_DIR)/$(KCONFIG_HOST_SOURCE) | $(TOOLS_SOURCE_DIR)
	tar -C $(TOOLS_SOURCE_DIR) $(VERBOSE) -xf $(DL_DIR)/$(KCONFIG_HOST_SOURCE)
	$(call APPLY_PATCHES,$(KCONFIG_HOST_MAKE_DIR)/patches,$(KCONFIG_HOST_DIR))
	$(if $(FREETZ_REAL_DEVELOPER_ONLY__BUTTONS),$(call APPLY_PATCHES,$(KCONFIG_HOST_MAKE_DIR)/patches/buttons,$(KCONFIG_HOST_DIR)))
	touch $@

$(KCONFIG_HOST_DIR)/.prerequisites: $(KCONFIG_HOST_DIR)/.unpacked
	@prmiss="";\
	for prereq in $(KCONFIG_HOST_BUILD_PREREQ); do which $${prereq} &>/dev/null || prmiss="$${prmiss} $${prereq}"; done; \
	if [ -n "$${prmiss}" ]; then \
		for prereq in $${prmiss}; do echo "Prerequisite '$${prereq}' is missing!"; done; \
		echo "See https://freetz-ng.github.io/freetz-ng/PREREQUISITES for installation hints" && exit 1; \
	fi
	touch $@

$(KCONFIG_HOST_DIR)/scripts/kconfig/conf: $(KCONFIG_HOST_DIR)/.prerequisites
	$(MAKE) -C $(KCONFIG_HOST_DIR) config

$(KCONFIG_HOST_DIR)/scripts/kconfig/mconf: $(KCONFIG_HOST_DIR)/.prerequisites
	$(MAKE) -C $(KCONFIG_HOST_DIR) menuconfig

$(KCONFIG_HOST_TARGET_DIR)/conf: $(KCONFIG_HOST_DIR)/scripts/kconfig/conf
	$(INSTALL_FILE)

$(KCONFIG_HOST_TARGET_DIR)/mconf: $(KCONFIG_HOST_DIR)/scripts/kconfig/mconf
	$(INSTALL_FILE)

kconfig-host-precompiled: $(KCONFIG_HOST_TARGET_DIR)/conf $(KCONFIG_HOST_TARGET_DIR)/mconf


kconfig-host-clean:
	$(RM) \
		$(KCONFIG_HOST_DIR)/scripts/basic/.*.cmd \
		$(KCONFIG_HOST_DIR)/scripts/kconfig/.*.cmd \
		$(KCONFIG_HOST_DIR)/scripts/kconfig/lxdialog/.*.cmd \
		$(KCONFIG_HOST_DIR)/scripts/kconfig/*.o \
		$(KCONFIG_HOST_DIR)/scripts/kconfig/lxdialog/*.o \
		$(KCONFIG_HOST_DIR)/scripts/kconfig/zconf.*.c \
		$(KCONFIG_HOST_DIR)/scripts/basic/fixdep \
		$(KCONFIG_HOST_DIR)/scripts/kconfig/conf \
		$(KCONFIG_HOST_DIR)/scripts/kconfig/mconf

kconfig-host-dirclean:
	$(RM) -r $(KCONFIG_HOST_DIR)

kconfig-host-distclean: kconfig-host-dirclean
	$(RM) -r $(KCONFIG_HOST_TARGET_DIR)/

.PHONY: kconfig-host-source kconfig-host-unpacked kconfig-host kconfig-host-clean kconfig-host-dirclean kconfig-host-distclean

