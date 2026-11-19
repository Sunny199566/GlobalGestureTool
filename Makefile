ARCHS = arm64 arm64e
TARGET = iphone:clang:17.0:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GlobalGestureTool
GlobalGestureTool_FILES = Tweak.x IOHIDTouch.m
GlobalGestureTool_CFLAGS = -fobjc-arc
GlobalGestureTool_FRAMEWORKS = UIKit CoreGraphics
GlobalGestureTool_PRIVATE_FRAMEWORKS = IOKit

# rootless 关键配置（适配 NathanLR）
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS_MAKE_PATH)/tweak.mk