#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Base product configuration. The recovery only needs 64-bit binaries: every
# vendor blob it ships is arm64.
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)

PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH)

# The stock vendor launched with Android 14 (API 34); the LineageOS tree ships
# the same value.
PRODUCT_SHIPPING_API_LEVEL := 34
