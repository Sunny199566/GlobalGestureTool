ARCHS = arm64e
TARGET = iphone:clang:17.0:14.5

THEOS_PACKAGE_SCHEME = rootless
THEOS_PACKAGE_INSTALL_PREFIX = /var/jb

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = GestureManager
GestureManager_SWIFT_FILES = main.swift
GestureManager_FRAMEWORKS = UIKit SwiftUI Foundation

include $(THEOS_MAKE_PATH)/application.mk