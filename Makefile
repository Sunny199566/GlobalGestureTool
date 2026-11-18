ARCHS = arm64e
TARGET = iphone:clang:17.0:17.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += RecordTweak GestureManager PlayDaemon

include $(THEOS_MAKE_PATH)/aggregate.mk