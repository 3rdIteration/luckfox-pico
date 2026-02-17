################################################################################
#
# libxcrypt - Override for Luckfox Pico to enable obsolete API
#
################################################################################

LIBXCRYPT_VERSION = 4.4.36
LIBXCRYPT_SITE = https://github.com/besser82/libxcrypt/releases/download/v$(LIBXCRYPT_VERSION)
LIBXCRYPT_SOURCE = libxcrypt-$(LIBXCRYPT_VERSION).tar.xz
LIBXCRYPT_LICENSE = LGPL-2.1+
LIBXCRYPT_LICENSE_FILES = LICENSING COPYING.LIB
LIBXCRYPT_INSTALL_STAGING = YES

# Some warnings turn into errors with some sensitive compilers
LIBXCRYPT_CONF_OPTS = --disable-werror
HOST_LIBXCRYPT_CONF_OPTS = --disable-werror

# MODIFIED: Enable obsolete API for compatibility with old code like android-tools/adbd
# The obsolete API includes the traditional crypt() function which is needed by adbd
LIBXCRYPT_CONF_OPTS += --enable-obsolete-api
HOST_LIBXCRYPT_CONF_OPTS += --enable-obsolete-api

$(eval $(autotools-package))
$(eval $(host-autotools-package))
