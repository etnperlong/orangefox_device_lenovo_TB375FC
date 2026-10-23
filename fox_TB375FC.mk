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

# Screen height in theme units for a 1080-unit wide theme: the logical canvas
# is 1840x2944 (9:14.4), so 14.4 * 120 = 1728. This keeps the theme scaling
# uniform (1840/1080 = 2944/1728). No display cutout: the status bar keeps
# its default height.
OF_SCREEN_H := 1728
