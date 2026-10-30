#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# OrangeFox build settings that are read as make variables. The FOX_*
# environment switches live in vendorsetup.sh.

# Ramdisk compression: match BOARD_RAMDISK_USE_LZ4 and the stock LZ4 vendor
# ramdisks.
OF_USE_LZ4_COMPRESSION := 1

# Landscape panel. OF_LANDSCAPE_MODE makes minuitwrp default to a 270 degree
# rotation: the UI is laid out on a 1840x2944 portrait canvas that is drawn
# onto the 2944x1840 panel.
#
# Touch needs no swap or flip flags. The NT36532 reports raw X along the short
# edge (0-18400) and raw Y along the long edge (0-29440), i.e. already in
# portrait order. minuitwrp scales them to the logical canvas,
#   u = x * 1839 / 18400, v = y * 2943 / 29440,
# and the 270 degree renderer draws logical (u, v) at panel (v, 1839 - u).
# That is the mapping the LineageOS recovery applies with
# ro.minui.default_touch_rotation=ROTATION_RIGHT. Touch rotation is not
# applied on top of this, so RECOVERY_TOUCHSCREEN_SWAP_XY/FLIP_* would break
# it.
OF_LANDSCAPE_MODE := 1

# Screen height in theme units for the 1080-unit wide theme. The logical
# canvas is 1840x2944, so 1728 would scale both axes by 1.70 (1840/1080) and
# draw a magnified phone layout. 2304 keeps the horizontal scale and lowers the
# vertical scale, and with it fonts and aspect-locked icons (they follow the
# smaller scale), to 2944/2304 = 1.28: text and icons are 75% of the uniform
# size and lists show more rows. Elements without retainaspect (key and dialog
# backgrounds, progress bars) are stretched 1.33x horizontally. No display
# cutout: the status bar keeps its default height.
OF_SCREEN_H := 2304

# Dynamic partitions: build lptools for the Super partition manager
OF_ENABLE_LPTOOLS := 1

# LineageOS is a Treble ROM; skip the legacy Treble check of zip installs
OF_NO_TREBLE_COMPATIBILITY_CHECK := 1

# Quick backup: both boot images the ROM updates, and data
OF_QUICK_BACKUP_LIST := /boot;/vendor_boot;/data;

# Data format with metadata encryption: unbind /sdcard before the f2fs
# format, wipe /metadata afterwards so the ROM's vold creates a new metadata
# key for the fresh userdata, and re-bind /sdcard for MTP.
OF_UNBIND_SDCARD_F2FS := 1
OF_WIPE_METADATA_AFTER_DATAFORMAT := 1
OF_BIND_MOUNT_SDCARD_ON_FORMAT := 1

# The torch is driven through the /dev/flashlight ioctl interface of the
# MediaTek flashlight.ko on vendor_dlkm, which the recovery does not load;
# there is no LED class node the recovery could switch.
OF_FLASHLIGHT_ENABLE := 0

# Battery level from sysfs. The default path asks the health HAL, which the
# recovery doesn't run (no IHealth in its VINTF manifest, no hwservicemanager),
# so GetBatteryInfo() falls back to a fake 100%. The mm8013 fuel gauge in
# vendor_ramdisk00 registers /sys/class/power_supply/battery, the default
# legacy path, with capacity and status in the recovery too.
OF_USE_LEGACY_BATTERY_SERVICES := 1
