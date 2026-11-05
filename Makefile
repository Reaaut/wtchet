TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = WeChat

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = wtchet
wtchet_FILES = Sources/Tweak.x Sources/WTSettingsController.m Sources/WTInputSettingsController.m
wtchet_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
wtchet_FRAMEWORKS = UIKit Foundation
wtchet_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
