ARCHS = arm64
TARGET = iphone:clang:16.5:15.0
# ✅ 核心！开启rootless打包，deb架构自动变成 iphoneos-arm64
THEOS_PACKAGE_SCHEME = rootless

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GlobalGestureTool

GlobalGestureTool_FILES = Tweak.x IOHIDTouch.m
GlobalGestureTool_FRAMEWORKS = UIKit IOKit
GlobalGestureTool_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk