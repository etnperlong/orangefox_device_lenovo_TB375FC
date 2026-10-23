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
