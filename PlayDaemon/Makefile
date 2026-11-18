ARCHS = arm64e
TARGET = iphone:clang:16.5:14.5

THEOS_PACKAGE_SCHEME = rootless
THEOS_PACKAGE_INSTALL_PREFIX = /var/jb

include $(THEOS)/makefiles/common.mk

EXECUTABLE_NAME = PlayDaemon
PlayDaemon_FILES = PlayDaemon.m
PlayDaemon_CFLAGS = -fobjc-arc
PlayDaemon_FRAMEWORKS = UIKit Foundation CoreGraphics
PlayDaemon_CODESIGN_FLAGS = -SPlayDaemon.entitlements

include $(THEOS_MAKE_PATH)/executable.mk