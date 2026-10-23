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

# Kernel. The GKI kernel ships in the ROM's boot.img, and the recovery lives in
# vendor_boot, which carries no kernel. This tree never builds boot.img.
TARGET_NO_KERNEL                := true
BOARD_USES_GENERIC_KERNEL_IMAGE := true

# vendor_boot (header v4). Layout of the stock and LineageOS images:
# kernel@0x40000000, ramdisk@0x66f00000, tags@0x47c80000, dtb@0x47c80000.
# The build only injects --base and --pagesize into the vendor_boot mkbootimg
# call, so the offsets and the DTB are passed through BOARD_MKBOOTIMG_ARGS.
BOARD_KERNEL_BASE                := 0x40000000
BOARD_KERNEL_PAGESIZE            := 4096
BOARD_KERNEL_OFFSET              := 0x00000000
BOARD_RAMDISK_OFFSET             := 0x26f00000
BOARD_KERNEL_TAGS_OFFSET         := 0x07c80000
BOARD_DTB_OFFSET                 := 0x07c80000
BOARD_BOOT_HEADER_VERSION        := 4
BOARD_VENDOR_BOOT_HEADER_VERSION := 4

# DTB from the stock 1.5.10.103 vendor_boot, the same file the LineageOS tree
# ships. It also carries the long stock cmdline in /chosen/bootargs.
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/prebuilt/dtb.img

BOARD_MKBOOTIMG_ARGS := --header_version $(BOARD_BOOT_HEADER_VERSION) \
    --kernel_offset  $(BOARD_KERNEL_OFFSET) \
    --ramdisk_offset $(BOARD_RAMDISK_OFFSET) \
    --tags_offset    $(BOARD_KERNEL_TAGS_OFFSET) \
    --dtb_offset     $(BOARD_DTB_OFFSET) \
    --dtb            $(TARGET_PREBUILT_DTB)

# Vendor cmdline of the stock and LineageOS vendor_boot. firmware_class.path
# makes the kernel firmware loader look in /vendor/firmware first.
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2 firmware_class.path=/vendor/firmware
BOARD_BOOTCONFIG :=

# The stock vendor ramdisks are LZ4.
BOARD_RAMDISK_USE_LZ4 := true

# Recovery as the "recovery" ramdisk fragment of vendor_boot. There is no
# recovery partition; the bootloader boots the same vendor_boot for both modes.
BOARD_USES_RECOVERY_AS_BOOT                   :=
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT  := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE         := 67108864

# AVB: vendor_boot gets a hash footer like the LineageOS image.
BOARD_AVB_ENABLE := true

# Kernel modules
include $(DEVICE_PATH)/tb375fc-kernel-modules.mk

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
