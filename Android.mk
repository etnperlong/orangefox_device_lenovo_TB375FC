#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),TB375FC)
include $(call all-makefiles-under,$(LOCAL_PATH))

# The DTB reaches mkbootimg only through BOARD_MKBOOTIMG_ARGS, so the build
# does not know vendor_boot.img depends on it. Declare it, so that replacing
# the DTB rebuilds the image.
$(PRODUCT_OUT)/vendor_boot.img: $(TARGET_PREBUILT_DTB)
endif
