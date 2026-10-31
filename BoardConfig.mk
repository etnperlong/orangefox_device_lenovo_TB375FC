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

# DTB from the stock 1.5.10.123 vendor_boot, the same file the LineageOS tree
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

# Recovery fstab. The vendor fstab is not merged in: the recovery re-reads the
# /data and /metadata lines of that "additional fstab", and its last /data line
# is /dev/block/dm-userdata, which does not exist before the ROM's vold runs.
TARGET_RECOVERY_FSTAB   := $(DEVICE_PATH)/recovery.fstab
TW_SKIP_ADDITIONAL_FSTAB := true
RECOVERY_SDCARD_ON_DATA := true

# USB: the device tree provides a configfs init.recovery.usb.rc
TW_EXCLUDE_DEFAULT_USB_INIT := true

# Display: 12.7" 2944x1840 LCD, native landscape. OrangeFox draws its portrait
# theme on a 270 degree rotated canvas (OF_LANDSCAPE_MODE in fox_TB375FC.mk),
# so TW_ROTATION must stay unset: a valid TW_ROTATION takes precedence over
# OF_LANDSCAPE_MODE.
TW_THEME := portrait_hdpi
# Same format as the LineageOS recovery (DRM XBGR8888).
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
# Backlight: the MediaTek lcd-backlight LED class node takes 0-4095
# (its max_brightness in the recovery). Start at half of it, the normal
# brightness of the AOSP recovery UI that the LineageOS recovery keeps (50%).
TW_BRIGHTNESS_PATH := "/sys/class/leds/lcd-backlight/brightness"
TW_MAX_BRIGHTNESS := 4095
TW_DEFAULT_BRIGHTNESS := 2048
TW_FRAMERATE := 60
TW_EXTRA_LANGUAGES := true

# Build-time placeholders used by the official OrangeFox reference trees.
# 99.87.36 is accepted by the CTS version check, not the installed ROM's OS
# version. The future patch levels must never reach beanpod KeyMint either:
# vold can persist upgraded key blobs that the ROM can no longer decrypt.
#
# beforemodules.sh reads the active ROM's system and vendor build.prop,
# restores all three KeyMint version properties, and verifies them before
# opening a separate init gate. Any failure leaves KeyMint disabled; there
# is no build-time fallback for decryption. The ramdisk preparation hook
# below also prevents foxstart.sh from replacing the verified OS release.
PLATFORM_VERSION             := 99.87.36
PLATFORM_VERSION_LAST_STABLE := 99.87.36
VENDOR_SECURITY_PATCH        := 2099-12-31
PLATFORM_SECURITY_PATCH      := $(VENDOR_SECURITY_PATCH)

# Specialize only the generated ramdisk; leave the upstream source intact.
# The helper checks the reviewed foxstart.sh source and updates its ramdisk
# checksum. An upstream change requires review instead of silently dropping
# the protection. Android.mk declares the helper and source dependencies.
BOARD_RECOVERY_IMAGE_PREPARE += python3 $(DEVICE_PATH)/tools/prepare-recovery.py --ramdisk "$(TARGET_RECOVERY_ROOT_OUT)" --source vendor/recovery/FoxExtras/sbin/foxstart.sh

# First API level of the stock vendor, as in the LineageOS tree
# (ro.board.first_api_level; ro.product.first_api_level comes from
# PRODUCT_SHIPPING_API_LEVEL).
BOARD_SHIPPING_API_LEVEL := 34

# The v34 libcrypto.so of the TEE stack is an ELF installed with
# PRODUCT_COPY_FILES (device.mk).
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# Decryption: FBEv2 (aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized) with
# metadata encryption, keys in KeyMint on the beanpod TEE. fscrypt policy v2 is
# the default.
TW_INCLUDE_CRYPTO               := true
TW_INCLUDE_CRYPTO_FBE           := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true

# Load_Vendor_Modules() synchronously runs beforemodules.sh from
# Process_Fstab(), before Setup_Fstab_Partitions() first decrypts /data.
# Our hook restores the ROM OS release and both patch levels and fails
# closed. The loader then reads the same ROM patch levels and finally sets
# twrp.modules.loaded=true. KeyMint requires both completion gates and the
# TEE daemon's INIT_OK. It runs from the recovery's /system so mounting the
# ROM's /vendor during decryption cannot replace its binaries or libraries.
#
# The loader only runs when TW_LOAD_VENDOR_MODULES names a module. The touch
# driver is named because first-stage init has already loaded it from
# vendor_ramdisk00, so the loader loads nothing; it only copies the module
# directories of the ROM's /vendor and /vendor_dlkm to /tmp before noticing.
# TW_LOAD_VENDOR_BOOT_MODULES must stay unset; with it the loader checks the
# vendor_boot modules first, sees them all loaded and returns before reading
# the patch levels.
TW_LOAD_VENDOR_MODULES := "nt36532.ko"

# The ROM's APEXes are Android 17 builds; the TEE stack lives in the recovery
# ramdisk and needs none of them.
TW_EXCLUDE_APEX := true

# logd and logcat. teei_daemon, KeyMint, keystore2 and vold report decryption
# failures only to logcat, not to the recovery log.
TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD    := true

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
