ARCHS = arm64e
export TARGET = iphone:clang:16.5:14.5

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = GestureManager
GestureManager_FILES = main.m
GestureManager_FRAMEWORKS = UIKit Foundation
GestureManager_INFO_PLIST = Info.plist

# 核心：输出格式改为ipa，不再打包deb
PACKAGE_FORMAT = ipa

include $(THEOS_MAKE_PATH)/application.mk