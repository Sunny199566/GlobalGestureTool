ARCHS = arm64e
export TARGET = iphone:clang:16.5:14.5
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = GestureManager
GestureManager_FILES = main.m
GestureManager_FRAMEWORKS = UIKit Foundation
# ✅新增这一行，指定Info.plist，编译的时候自动打进.app包里面
GestureManager_INFO_PLIST = Info.plist

include $(THEOS_MAKE_PATH)/application.mk