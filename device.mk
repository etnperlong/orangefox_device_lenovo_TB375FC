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

# Novatek NT36532 touch firmware. nt36532.ko requests it during first-stage
# init, before any /vendor is mounted, so the kernel loader finds it only in
# vendor_ramdisk00 at /vendor/firmware (firmware_class.path). In normal boot
# the real /vendor mount hides the copy.
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/prebuilt/firmware/novatek_ts_fw_boe.bin:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/vendor/firmware/novatek_ts_fw_boe.bin \
    $(DEVICE_PATH)/prebuilt/firmware/novatek_ts_fw_tm.bin:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/vendor/firmware/novatek_ts_fw_tm.bin \
    $(DEVICE_PATH)/prebuilt/firmware/novatek_ts_mp_boe.bin:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/vendor/firmware/novatek_ts_mp_boe.bin \
    $(DEVICE_PATH)/prebuilt/firmware/novatek_ts_mp_tm.bin:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/vendor/firmware/novatek_ts_mp_tm.bin

# Userspace fastboot, so "fastboot reboot fastboot" and fastbootd flashing of
# logical partitions work from the recovery
PRODUCT_PACKAGES += \
    fastbootd

# Boot control HAL. The stock AIDL android.hardware.boot-service.mtk lives on
# /vendor; the LineageOS recovery switches slots with the AOSP passthrough
# HAL on top of the misc-based bootctrl.default instead.
PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-impl.recovery \
    bootctrl.default.recovery

# beanpod TEE stack (recovery/root/system and recovery/root/vendor). The stock
# vendor blobs were built against the v34 VNDK; libkeymaster_portable.so
# imports the unprefixed BoringSSL stack API (sk_num, sk_value, sk_push,
# sk_new_null) that only the v34 libcrypto.so exports. The LineageOS ROM
# overlays the same v34 library onto /vendor/lib64 (tb375fc-vndk-overlay.mk).
# Take it from the AOSP VNDK snapshot that the fox_16.0 manifest syncs, and
# keep it next to the HAL libraries, away from the recovery's own
# /system/lib64/libcrypto.so.
PRODUCT_COPY_FILES += \
    prebuilts/vndk/v34/arm64/arch-arm64-armv8-a/shared/vndk-core/libcrypto.so:$(TARGET_COPY_OUT_RECOVERY)/root/system/lib64/beanpod/libcrypto.so

# Task profiles for logd (TARGET_USES_LOGD). logd's DropPrivs() aborts with
# PLOG(FATAL) when set_sched_policy(SP_BACKGROUND) fails, and that needs the
# SCHED_SP_BACKGROUND profile. The task_profiles.json module has no recovery
# variant, so copy the file of the same libprocessgroup the recovery's logd
# is built with.
PRODUCT_COPY_FILES += \
    system/core/libprocessgroup/profiles/task_profiles.json:$(TARGET_COPY_OUT_RECOVERY)/root/system/etc/task_profiles.json
