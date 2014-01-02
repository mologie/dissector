#
# Makefile for Dissector
# http://cydia.mologie.com/package/com.moogie.dissector/
#

TWEAK_NAME = Dissector
Dissector_FILES = Tweak.x
Dissector_FRAMEWORKS = UIKit

# Use make DEBUG=1 for building binaries which output logs
DEBUG ?= 0
ifeq ($(DEBUG), 1)
	CFLAGS = -DDEBUG
endif

# Target the iPhone 3GS and all later devices
ARCHS = armv7 armv7s arm64
TARGET_IPHONEOS_DEPLOYMENT_VERSION := 3.0

# Let Theos do its magic
include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
