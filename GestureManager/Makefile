THEOS_PACKAGE_SCHEME = rootless
THEOS_PACKAGE_INSTALL_PREFIX = /var/jb

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = GestureManager
GestureManager_FILES = main.m
GestureManager_FRAMEWORKS = UIKit Foundation
# ✅新增下面这一行，告诉theos读取同目录Info.plist，打进app包
GestureManager_INFO_PLIST = Info.plist

include $(THEOS_MAKE_PATH)/application.mk