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

PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH)

# The stock vendor launched with Android 14 (API 34); the LineageOS tree ships
# the same value.
PRODUCT_SHIPPING_API_LEVEL := 34
