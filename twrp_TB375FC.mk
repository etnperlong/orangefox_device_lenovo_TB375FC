#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Release name
PRODUCT_RELEASE_NAME := TB375FC

DEVICE_PATH := device/lenovo/$(PRODUCT_RELEASE_NAME)

# Inherit from the device configuration
$(call inherit-product, $(DEVICE_PATH)/device.mk)

# Inherit the common TWRP/OrangeFox product configuration
$(call inherit-product, vendor/twrp/config/common.mk)

# Device identifier. This must come after all inclusions.
# PRODUCT_DEVICE matches the LineageOS product, so ROM packages that assert
# ro.product.device=TB375FC install from this recovery.
PRODUCT_NAME := twrp_$(PRODUCT_RELEASE_NAME)
PRODUCT_DEVICE := $(PRODUCT_RELEASE_NAME)
PRODUCT_BRAND := Lenovo
PRODUCT_MODEL := TB375FC
PRODUCT_MANUFACTURER := Lenovo
