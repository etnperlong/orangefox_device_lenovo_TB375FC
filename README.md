# OrangeFox device tree for the Lenovo TB375FC

OrangeFox Recovery (`fox_16.0`, Android 16) for the Lenovo Xiaoxin Pad Pro
12.7 2025 (TB375FC, PRC). The tree is a recovery-only port of the LineageOS
24.0 (Android 17) device tree for the same tablet, and the recovery is meant to
run alongside that ROM.

**Status:** tested on DerpFest 17 (2026-10-28 build): the recovery boots and
decrypts user 0 with a PIN. The ROM's `init_boot` must hold only the generic
ramdisk allow list. The bootloader loads it after `vendor_boot`, so a
`system/lib64` in it (libc, libm, libdl, ld-android of the ROM's Android
version) replaces this recovery's bionic and its init crashes on boot.

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
`OF_LANDSCAPE_MODE`.

`OF_SCREEN_H := 2304` sets the UI density. The theme is 1080 units wide, so the
horizontal scale is fixed at 1840/1080 = 1.70; the uniform height would be
1728. A taller theme height lowers the vertical scale to 2944/2304 = 1.28, and
fonts and aspect-locked icons follow the smaller scale, so they are 75% of the
uniform size while the layout still spans the full width. Elements without
`retainaspect` are stretched 1.33x horizontally. The value was chosen from an
on-device preview against 1728.

If the UI comes up rotated the wrong way, `persist.twrp.rotation` (0, 90, 180
or 270) overrides the default rotation at runtime; it does not change the touch
mapping.

### Decryption

KeyMint binds each key to the OS version and the OS and vendor patch levels it
reads from `ro.build.version.release`, `ro.build.version.security_patch` and
`ro.vendor.build.security_patch`. A higher value can upgrade a key blob that
vold writes back to `/metadata` or `/data`, leaving the ROM unable to use it.

The build follows the official OrangeFox reference convention:
`PLATFORM_VERSION` and `PLATFORM_VERSION_LAST_STABLE` are `99.87.36`, and both
security patch defaults are `2099-12-31`. The version passes the CTS build-time
allowlist check. None of these placeholders is a decryption fallback.

Before the first `Decrypt_Data()`, the vendor-module loader synchronously runs
the device's `/system/bin/beforemodules.sh`. It mounts the active-slot
`/dev/block/by-name/system` and `/dev/block/by-name/vendor` mappings at private
paths under `/tmp/twrp-romprops`, never over the recovery's `/system` or
`/vendor`. Mounts are read-only; ext4 also uses `noload` to prevent journal
replay. It reads the system release and system patch from `system/build.prop`,
and the vendor patch from `vendor`'s `build.prop`, without sourcing either
file. All three fields must be unique, valid, and different from the build
placeholders. The helper resets all three properties, checks their live
values, and unmounts its private mounts before setting
`twrp.keymint.props_ready=true`. It also requires the marker installed by the
ramdisk policy below, so a missing packaging adaptation cannot open the gate.

KeyMint is disabled until that property, `twrp.modules.loaded=true`, and the
TEE daemon's `INIT_OK` are all present. A missing helper, missing tool,
unreadable or invalid ROM property, mount/unmount failure, reset failure, or
readback mismatch leaves the property gate closed. The loader ignores the
hook's exit status, so the separate init gate is essential. The loader's
existing patch resets still run afterward and read the same ROM values;
they cannot substitute for the three-property check. Neither the helper nor
its failure handling reads or writes the ROM's key directories.

OrangeFox's normal `foxstart.sh` would later replace the global OS release
with a vendor-preferred value. `tools/prepare-recovery.py`, invoked through
`BOARD_RECOVERY_IMAGE_PREPARE`, removes only that assignment from the
**generated recovery ramdisk**, retaining ROM detection, OrangeFox metadata,
and the rest of startup. It does not edit `vendor/recovery` or any other
upstream source repository. The helper requires the reviewed upstream script
from `vendor/recovery@744dc8f61e697085f38eba353814ec903ea18933`; unexpected
source or generated content fails the build. It also refreshes the ramdisk
checksum entry, and the build dependency includes both scripts so an
incremental build reruns the policy. This keeps the verified system OS release
in effect for later KeyMint restarts without skipping OrangeFox initialization.

The design is inspired by Qualcomm's `prepdecrypt` property preparation, but
does not import its HALs or its error path that still signals crypto readiness.
These are source-level safety measures, not proof of a complete build or
on-device decryption.

For the first device test:

1. Back up data and keep the original `vendor_boot` available, or test only
   where data loss is acceptable. The recovery attempts metadata decryption
   during startup, before an ADB session can inspect its properties.
2. In recovery, check `getprop twrp.keymint.props_ready` is `true`. Check
   `getprop ro.build.version.release` matches the installed ROM (`17` for the
   current ROM), and both `getprop ro.build.version.security_patch` and
   `getprop ro.vendor.build.security_patch` match that ROM's property files,
   not `2099-12-31`. The current vendor baseline is `2026-05-05`.
3. Save `adb logcat -b all -d` and inspect KeyMint, keystore2, and vold for
   `KEY_REQUIRES_UPGRADE`, `upgradeKey`, and other decryption errors. Missing
   upgrade messages alone are not proof that no key was changed. If the gate
   is not `true`, keep KeyMint stopped; do not force-start it or force the
   readiness property.
4. After testing recovery decryption, reboot to the ROM and confirm the
   existing credentials still unlock it.

The TEE stack (`teei_daemon`, KeyMint, Gatekeeper, their libraries, the trusted
applications and the VINTF fragments) comes from the stock vendor image that
the LineageOS tree uses. `teei_daemon` stays in `/vendor` and starts on `fs`
with `persist` mounted read-only at `/mnt/vendor/persist`, its fallback for a
virtual RPMB. This tablet uses the UFS RPMB unit (`/dev/0:0:0:49476`), which
the daemon opens only after it has dropped to `system`. The recovery therefore
sets the TEE and RPMB device nodes to the stock owners and modes before it
starts the daemon: the Gatekeeper TA binds its failure records to RPMB, sets
RPMB up once when it loads, and otherwise fails every verify with
`search uid failed`. KeyMint and Gatekeeper run from `/system/bin` with their
libraries in `/system/lib64/beanpod`: before decryption the recovery mounts the
ROM's vendor partition over `/vendor` more than once, while `/system` always
stays the ramdisk. They use the v34 `libcrypto.so` that the ROM also uses for
these blobs.

The recovery's VINTF main manifests (`/vendor/etc/vintf/manifest.xml` and
`/system/etc/vintf/manifest.xml`) are minimal. They exist so that
servicemanager reads the HAL fragments; without them no HAL can register.

Check `adb logcat` in the recovery when decryption fails: `teei_daemon`,
KeyMint, keystore2 and vold only log there. The recovery ships
`task_profiles.json` for this: without it logd aborts at startup and logcat
has nothing to read.

## Sources

- LineageOS 24.0 device tree for the TB375FC: partition layout, `vendor_boot`
  layout, kernel modules, fstab, touch firmware, USB controller, boot control
- Stock ZUXOS 1.5.10.103 vendor (through the LineageOS vendor tree): DTB, TEE
  stack
- OrangeFox fox_16.0 device trees (mondrian, sm84xx-common, alioth): layout,
  configfs USB script, vendor_boot settings
