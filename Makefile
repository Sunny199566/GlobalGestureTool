ARCHS = arm64
TARGET = iphone:clang:16.5:15.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GlobalGestureTool

GlobalGestureTool_FILES = Tweak.x IOHIDTouch.m
GlobalGestureTool_FRAMEWORKS = UIKit IOKit
GlobalGestureTool_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk