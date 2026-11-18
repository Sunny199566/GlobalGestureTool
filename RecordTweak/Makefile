ARCHS = arm64e
TARGET = iphone:clang:17.0:14.5
INSTALL_TARGET_PROCESSES = 

THEOS_PACKAGE_SCHEME = rootless
THEOS_PACKAGE_INSTALL_PREFIX = /var/jb

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RecordTweak
RecordTweak_FILES = Tweak.x
RecordTweak_CFLAGS = -fobjc-arc
RecordTweak_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk