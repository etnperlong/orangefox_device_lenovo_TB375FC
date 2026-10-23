#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/lenovo/TB375FC

# Architecture
TARGET_ARCH                := arm64
TARGET_ARCH_VARIANT        := armv8-a
TARGET_CPU_ABI             := arm64-v8a
TARGET_CPU_ABI2            :=
TARGET_CPU_VARIANT         := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a55

TARGET_2ND_ARCH                := arm
TARGET_2ND_ARCH_VARIANT        := armv8-2a
TARGET_2ND_CPU_ABI             := armeabi-v7a
TARGET_2ND_CPU_ABI2            := armeabi
TARGET_2ND_CPU_VARIANT         := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55

# Platform
TARGET_BOARD_PLATFORM        := mt6897
TARGET_BOOTLOADER_BOARD_NAME := mt6897
TARGET_NO_BOOTLOADER         := true

# Assert
TARGET_OTA_ASSERT_DEVICE := TB375FC

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    vendor_boot \
    init_boot \
    dtbo \
    odm \
    odm_dlkm \
    product \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor \
    vendor \
    vendor_dlkm

# Partitions
TARGET_COPY_OUT_VENDOR      := vendor
TARGET_COPY_OUT_PRODUCT     := product
TARGET_COPY_OUT_SYSTEM_EXT  := system_ext
TARGET_COPY_OUT_ODM         := odm
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
TARGET_COPY_OUT_ODM_DLKM    := odm_dlkm
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm

BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_USES_METADATA_PARTITION := true

# Dynamic partitions. Values from the stock super layout, as in the LineageOS
# tree: Virtual A/B keeps one group of at most half of super, minus 4 MiB of
# metadata.
BOARD_SUPER_PARTITION_SIZE   := 9663676416
BOARD_SUPER_PARTITION_GROUPS := main
BOARD_MAIN_SIZE              := 4827643904
BOARD_MAIN_PARTITION_LIST    := system system_ext system_dlkm vendor vendor_dlkm product odm odm_dlkm

# File systems. Every logical partition of the ROM is EROFS; userdata and
# metadata are F2FS.
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE      := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE  := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE     := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE      := erofs
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE         := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODM_DLKMIMAGE_FILE_SYSTEM_TYPE    := erofs
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE    := f2fs

TARGET_USERIMAGES_USE_EXT4  := true
TARGET_USERIMAGES_USE_F2FS  := true
TARGET_USERIMAGES_USE_EROFS := true
BOARD_HAS_LARGE_FILESYSTEM  := true
