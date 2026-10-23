# OrangeFox device tree for the Lenovo TB375FC

OrangeFox Recovery (`fox_16.0`, Android 16) for the Lenovo Xiaoxin Pad Pro
12.7 2025 (TB375FC, PRC). The tree is a recovery-only port of the LineageOS
24.0 (Android 17) device tree for the same tablet, and the recovery is meant to
run alongside that ROM.

**Status:** this tree has not been built or tested on a device yet.

| | |
|---|---|
| SoC | MediaTek Dimensity 8300 (MT6897) |
| Display | 12.7" 2944x1840 LCD, native landscape |
| Touch | Novatek NT36532 |
| Kernel | GKI 6.1 in the ROM's `boot.img` |
| Boot image | `vendor_boot` header v4; the recovery is its `recovery` ramdisk fragment |
| Partitions | A/B, Virtual A/B with compression, dynamic partitions (`super`) |
| Storage encryption | FBEv2 with metadata encryption |
| TEE | Microtrust (beanpod) KeyMint 3 and Gatekeeper |

## Building

Sync the OrangeFox `fox_16.0` manifest and place this repository at
`device/lenovo/TB375FC`:

```bash
repo init -u https://gitlab.com/OrangeFox/Manifest.git -b fox_16.0
repo sync
# add this repository to a local manifest at device/lenovo/TB375FC
repo sync

export FOX_BUILD_DEVICE=TB375FC
source build/envsetup.sh
lunch twrp_TB375FC-bp2a-eng
mka vendorbootimage
```

The tree needs nothing besides the manifest. `prebuilts/vndk/v34` provides the
v34 `libcrypto.so` of the TEE stack; every other blob is part of this tree.

The build produces `vendor_boot.img` and an OrangeFox zip that contains the
recovery fragment as `vendor_ramdisk_recovery.cpio`. The `vendor_boot`
partition is 64 MiB. If the image ends up too large, see the size options of
the OrangeFox build variables (for example `FOX_DRASTIC_SIZE_REDUCTION`).

## Installing

The recovery is the `recovery` fragment of `vendor_boot`. Replacing only that
fragment keeps the ROM's `vendor_ramdisk00`, DTB and cmdline. This needs
userspace fastboot (`fastboot fetch`), which the LineageOS recovery provides.

Any change to `vendor_boot`, fragment or full image, no longer matches the
`vendor_boot` hash in the ROM's `vbmeta`. The LineageOS install, which flashes
its own `vendor_boot` over the stock `vbmeta`, suggests that the unlocked
bootloader accepts that, but it has not been tested with this recovery, and
this bootloader is known to reject a mismatching `dtbo` hash. For the first
test, keep the backup from step 2 and the LineageOS `vendor_boot.img` at hand;
the bootloader's own fastboot can always restore it.

1. Boot the LineageOS recovery and enter fastbootd (Advanced, Enter fastboot).
2. Back up the current image: `fastboot fetch vendor_boot vendor_boot-los.img`
3. Flash the fragment:
   `fastboot flash vendor_boot:recovery vendor_ramdisk_recovery.cpio`
4. Reboot to the recovery.

To go back, flash the backup from the bootloader:
`fastboot flash vendor_boot vendor_boot-los.img`. `fastboot boot` does not work
for a Virtual A/B device with a vendor_boot recovery.

Flashing only the fragment skips the build's size check of the 64 MiB
partition; the full `vendor_boot.img` of the same build must have passed it.

Every LineageOS update writes a new `vendor_boot` with the LineageOS recovery
to the updated slot. Flash the fragment again after an update.

## Design notes

### vendor_boot

The tree reproduces `vendor_ramdisk00` of the LineageOS tree: the same 222
`vendor_ramdisk` kernel modules and load order (`tb375fc-kernel-modules.mk`,
including the patched `nt36532.ko` and `hall.ko`), the first-stage fstab, the
Novatek touch firmware, and snapuserd, linker and fsck from
`virtual_ab_ota/compression.mk`. The DTB, offsets and vendor cmdline are those
of the LineageOS `vendor_boot`. Apart from the AVB hash (see Installing), a
full `vendor_boot.img` from this tree carries the same ramdisk for the ROM;
installing the fragment alone still changes less.

### Landscape display and touch

fox_16.0 ships only the `portrait_hdpi` theme. `OF_LANDSCAPE_MODE := 1` rotates
the UI by 270 degrees onto a 1840x2944 portrait canvas. The touch controller
already reports portrait coordinates, and the rotated renderer maps logical
`(u, v)` to panel `(v, 1839 - u)`, the same transform as the LineageOS
recovery's `ROTATION_RIGHT`. No `RECOVERY_TOUCHSCREEN_*` flags are needed, and
`TW_ROTATION` must stay unset because it takes precedence over
`OF_LANDSCAPE_MODE`. `OF_SCREEN_H := 1728` keeps the theme scaling uniform.

If the UI comes up rotated the wrong way, `persist.twrp.rotation` (0, 90, 180
or 270) overrides the default rotation at runtime; it does not change the touch
mapping.

### Decryption

KeyMint binds each key to the OS version and the OS and vendor patch levels it
reads from `ro.build.version.release`, `ro.build.version.security_patch` and
`ro.vendor.build.security_patch`. A lower value than the key's makes KeyMint
refuse the key. A higher value upgrades the key, and vold writes the upgraded
blob back, after which the ROM can no longer use it. The recovery therefore
reports exactly what the ROM reports:

- OS version `17`, set at build time.
- Patch levels default to `2026-05-05`, the vendor patch level of the LineageOS
  tree. That is below every LineageOS 24.0 system patch level, so a stale
  default makes decryption fail instead of upgrading a key.
- Before decryption, the recovery reads the real values from the ROM's
  `/system` and `/vendor` `build.prop` (`TW_INCLUDE_CRYPTO` together with
  `TW_LOAD_VENDOR_MODULES`) and only then starts KeyMint.

The TEE stack (`teei_daemon`, KeyMint, Gatekeeper, their libraries, the trusted
applications and the VINTF fragments) comes from the stock vendor image that
the LineageOS tree uses. `teei_daemon` stays in `/vendor` and starts on `fs`
with `persist` mounted read-only at `/mnt/vendor/persist`, where it reads its
RPMB state. KeyMint and Gatekeeper run from `/system/bin` with their libraries
in `/system/lib64/beanpod`: before decryption the recovery mounts the ROM's
vendor partition over `/vendor` more than once, while `/system` always stays
the ramdisk. They use the v34 `libcrypto.so` that the ROM also uses for these
blobs.

The recovery's VINTF main manifests (`/vendor/etc/vintf/manifest.xml` and
`/system/etc/vintf/manifest.xml`) are minimal. They exist so that
servicemanager reads the HAL fragments; without them no HAL can register.

Check `adb logcat` in the recovery when decryption fails: `teei_daemon`,
KeyMint, keystore2 and vold only log there.

## Sources

- LineageOS 24.0 device tree for the TB375FC: partition layout, `vendor_boot`
  layout, kernel modules, fstab, touch firmware, USB controller, boot control
- Stock ZUXOS 1.5.10.103 vendor (through the LineageOS vendor tree): DTB, TEE
  stack
- OrangeFox fox_16.0 device trees (mondrian, sm84xx-common, alioth): layout,
  configfs USB script, vendor_boot settings
