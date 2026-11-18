ARCHS = arm64e
# 重点：编译SDK=16.5，最低部署14.5
export TARGET = iphone:clang:16.5:14.5
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += RecordTweak
SUBPROJECTS += GestureManager
SUBPROJECTS += PlayDaemon

include $(THEOS_MAKE_PATH)/aggregate.mk