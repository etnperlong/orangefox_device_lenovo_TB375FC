#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Base product configuration. The recovery only needs 64-bit binaries: every
# vendor blob it ships is arm64.
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)

# Virtual A/B with compression, as in the LineageOS tree. Besides the
# ro.virtual_ab.* properties this puts snapuserd, the linker and the fsck
# tools into vendor_ramdisk00, which first-stage init needs to boot the ROM
# from a snapshot.
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression.mk)

# Project quotas and casefolding, so that formatting data in the recovery
# matches what the ROM's vold expects.
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Dynamic partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# The tree ships no kernel, so the OTA kernel VINTF check has no kernel to
# read the release and config from.
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH)

# The stock vendor launched with Android 14 (API 34); the LineageOS tree ships
# the same value.
PRODUCT_SHIPPING_API_LEVEL := 34

# First-stage fstab, the same file the LineageOS tree installs. The bootloader
# reports ro.hardware=mt8792 while the DT is MT6897, so stock ships it under
# both names. vendor_ramdisk00 needs it to mount the ROM's logical partitions;
# the recovery ramdisk gets its own copy like the LineageOS recovery.
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/rootdir/etc/fstab.mt6897:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.mt6897 \
    $(DEVICE_PATH)/rootdir/etc/fstab.mt6897:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.mt8792 \
    $(DEVICE_PATH)/rootdir/etc/fstab.mt6897:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.mt6897 \
    $(DEVICE_PATH)/rootdir/etc/fstab.mt6897:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.mt8792
