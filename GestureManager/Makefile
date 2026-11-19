ARCHS = arm64e
export TARGET = iphone:clang:16.5:14.5
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = GestureManager
GestureManager_FILES = main.m
GestureManager_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/application.mk