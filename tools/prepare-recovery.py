#!/usr/bin/env python3
"""Apply the device-specific recovery ramdisk foxstart policy."""
import argparse
import hashlib
import os
import re
import stat
import sys
from pathlib import Path


PINNED_SOURCE_SHA256 = "08e3a680e666af0e953439b4cb45f160f18acb3bb058332e7ed27243d4fffc2b"
PINNED_SOURCE_COMMIT = "744dc8f61e697085f38eba353814ec903ea18933"
RELEASE_SETTER = (
    b'              $SETPROP "ro.build.version.release" "$tmp3" > /dev/null 2>&1\n'
)
READY_MARKER = b"              # TB375FC_KEYMINT_ROM_RELEASE_READY=1\n"
DEVICE_REWRITES = (
    (
        b'SYSTEM_BLOCK="/dev/block/bootdevice/by-name/system"\n',
        b'SYSTEM_BLOCK="/dev/block/mapper/system"\n',
    ),
    (
        b'VENDOR_BLOCK="/dev/block/bootdevice/by-name/vendor"\n',
        b'VENDOR_BLOCK="/dev/block/mapper/vendor"\n',
    ),
)


def fail(message):
    raise ValueError(message)


def resolve_ramdisk_path(root, parts):
    pending = list(parts)
    resolved = []
    followed_links = 0
    while pending:
        part = pending.pop(0)
        if part in ("", "."):
            continue
        if part == "..":
            if not resolved:
                fail("ramdisk symlink resolves outside the ramdisk")
            resolved.pop()
            continue

        candidate = root.joinpath(*resolved, part)
        mode = candidate.lstat().st_mode
        if stat.S_ISLNK(mode):
            followed_links += 1
            if followed_links > 40:
                fail("too many symlinks while resolving ramdisk path")
            link_target = os.readlink(str(candidate))
            link_parts = list(Path(link_target).parts)
            if os.path.isabs(link_target):
                resolved = []
                link_parts = link_parts[1:]
            pending = link_parts + pending
        else:
            resolved.append(part)
    return root.joinpath(*resolved)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ramdisk", required=True, type=Path)
    parser.add_argument("--source", required=True, type=Path)
    args = parser.parse_args()

    try:
        if not args.source.is_file():
            fail("pinned foxstart source is missing or not a file: {}".format(args.source))
        source = args.source.read_bytes()
        source_hash = hashlib.sha256(source).hexdigest()
        if source_hash != PINNED_SOURCE_SHA256:
            fail(
                "foxstart source SHA-256 mismatch for upstream {}: expected {}, got {}".format(
                    PINNED_SOURCE_COMMIT, PINNED_SOURCE_SHA256, source_hash
                )
            )

        staged_source = source
        for original, device_value in DEVICE_REWRITES:
            if staged_source.count(original) != 1:
                fail("pinned foxstart source lacks exactly one expected device partition assignment")
            staged_source = staged_source.replace(original, device_value, 1)
        if staged_source.count(RELEASE_SETTER) != 1:
            fail("pinned foxstart source does not contain exactly one known global release setter")
        patched_source = staged_source.replace(RELEASE_SETTER, READY_MARKER, 1)

        root = args.ramdisk.resolve(strict=True)
        if not root.is_dir():
            fail("ramdisk path is not a directory: {}".format(args.ramdisk))
        generated = resolve_ramdisk_path(root, ("sbin", "foxstart.sh"))
        if not generated.is_file():
            fail("generated foxstart target is not a regular file: {}/sbin/foxstart.sh".format(root))

        if generated.samefile(args.source):
            fail("generated foxstart resolves to the pinned source; refusing to modify upstream input")

        current = generated.read_bytes()
        if current == staged_source:
            needs_patch = True
        elif current == patched_source:
            needs_patch = False
        else:
            fail(
                "generated foxstart differs from the pinned source's exact TB375FC staging output: "
                "{}/sbin/foxstart.sh".format(root)
            )

        manifest = resolve_ramdisk_path(root, ("ramdisk-files.sha256sum",))
        if needs_patch and generated.stat().st_nlink != 1:
            fail("generated foxstart has multiple hard links; refusing to modify its aliases")
        if not manifest.is_file():
            fail("ramdisk checksum manifest is missing or not a regular file")
        if manifest.samefile(generated) or manifest.samefile(args.source):
            fail("ramdisk checksum manifest aliases a protected input file")
        manifest_data = manifest.read_bytes()
        expected_path = b"./" + generated.relative_to(root).as_posix().encode("utf-8")
        lines = manifest_data.splitlines(keepends=True)
        matching_lines = [index for index, line in enumerate(lines) if expected_path in line]
        if len(matching_lines) != 1:
            fail(
                "checksum manifest must contain exactly one entry for {} (found {})".format(
                    expected_path.decode("utf-8"), len(matching_lines)
                )
            )

        index = matching_lines[0]
        line = lines[index]
        row_pattern = re.compile(rb"([0-9a-f]{64})  " + re.escape(expected_path) + rb"(\n?)")
        match = row_pattern.fullmatch(line)
        if match is None:
            fail("checksum manifest entry for {} is malformed".format(expected_path.decode("utf-8")))
        expected_digest = hashlib.sha256(patched_source).hexdigest().encode("ascii")
        lines[index] = expected_digest + line[match.end(1) :]
        updated_manifest = b"".join(lines)
        if updated_manifest != manifest_data and manifest.stat().st_nlink != 1:
            fail("ramdisk checksum manifest has multiple hard links; refusing to modify its aliases")

        if needs_patch:
            generated.write_bytes(patched_source)
        if updated_manifest != manifest_data:
            manifest.write_bytes(updated_manifest)
    except (OSError, RuntimeError, ValueError) as error:
        print("prepare-recovery.py: {}".format(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())


