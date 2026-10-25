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

# The device's ramdisk policy must rerun when either the reviewed upstream
# startup script or its local specialization changes, including incremental
# builds. This is the timestamp target used by build/make/core/Makefile.
$(call intermediates-dir-for,PACKAGING,recovery)/ramdisk_files-timestamp: \
    $(LOCAL_PATH)/tools/prepare-recovery.py \
    vendor/recovery/FoxExtras/sbin/foxstart.sh
endif
