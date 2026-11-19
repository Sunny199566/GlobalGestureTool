ARCHS = arm64e
TARGET = iphone:clang:17.0:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GlobalGestureTool

GlobalGestureTool_FILES = Tweak.x IOHIDTouch.m
GlobalGestureTool_CFLAGS = -fobjc-arc
GlobalGestureTool_FRAMEWORKS = UIKit CoreGraphics IOKit
GlobalGestureTool_PRIVATE_FRAMEWORKS = IOHIDFamily

# rootless 关键配置
THEOS_PACKAGE_SCHEME = rootless
THEOS_PACKAGE_INSTALL_PREFIX = /var/jb

include $(THEOS_MAKE_PATH)/tweak.mk