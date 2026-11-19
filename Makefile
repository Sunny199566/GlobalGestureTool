ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GlobalGestureTool
GlobalGestureTool_FILES = Tweak.x IOHIDTouch.m
GlobalGestureTool_CFLAGS = -fobjc-arc
GlobalGestureTool_FRAMEWORKS = UIKit CoreGraphics
GlobalGestureTool_PRIVATE_FRAMEWORKS = IOKit

THEOS_PACKAGE_SCHEME = rootless

include $(THEOS_MAKE_PATH)/tweak.mk