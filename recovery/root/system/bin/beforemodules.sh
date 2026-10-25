#!/system/bin/sh
# Read the active ROM's build properties before normal module patch resets and
# allow the KeyMint init trigger only after every value has been restored.

SYSTEM_DEVICE=/dev/block/by-name/system
VENDOR_DEVICE=/dev/block/by-name/vendor
MOUNT_BASE=/tmp/twrp-romprops
SYSTEM_MOUNT=$MOUNT_BASE/system
VENDOR_MOUNT=$MOUNT_BASE/vendor
FOXSTART=/sbin/foxstart.sh
READY_MARKER='              # TB375FC_KEYMINT_ROM_RELEASE_READY=1'

system_mounted=0
vendor_mounted=0
base_created=0
system_dir_created=0
vendor_dir_created=0

close_gate() {
    if command -v setprop >/dev/null 2>&1; then
        setprop twrp.keymint.props_ready false >/dev/null 2>&1 || :
    fi
}

finish() {
    status=$1
    trap - 0 HUP INT TERM

    if [ "$status" -ne 0 ]; then
        close_gate
    fi

    if [ "$vendor_mounted" -eq 1 ]; then
        umount "$VENDOR_MOUNT" || status=1
        vendor_mounted=0
    fi
    if [ "$system_mounted" -eq 1 ]; then
        umount "$SYSTEM_MOUNT" || status=1
        system_mounted=0
    fi
    if [ "$vendor_dir_created" -eq 1 ]; then
        rmdir "$VENDOR_MOUNT" || status=1
        vendor_dir_created=0
    fi
    if [ "$system_dir_created" -eq 1 ]; then
        rmdir "$SYSTEM_MOUNT" || status=1
        system_dir_created=0
    fi
    if [ "$base_created" -eq 1 ]; then
        rmdir "$MOUNT_BASE" || status=1
        base_created=0
    fi

    if [ "$status" -ne 0 ]; then
        close_gate
        echo "beforemodules: ROM properties were not prepared; KeyMint remains disabled" >&2
    fi
    exit "$status"
}

trap 'finish $?' 0
trap 'exit 1' HUP INT TERM

fail() {
    exit 1
}

# This property starts false on init. Close it again before doing any work so
# every early return, including a missing command, leaves KeyMint disabled.
command -v setprop >/dev/null 2>&1 || fail
command -v getprop >/dev/null 2>&1 || fail
setprop twrp.keymint.props_ready false >/dev/null 2>&1 || fail
gate_state=$(getprop twrp.keymint.props_ready 2>/dev/null) || fail
[ "$gate_state" = false ] || fail

command -v resetprop >/dev/null 2>&1 || fail
command -v mount >/dev/null 2>&1 || fail
command -v umount >/dev/null 2>&1 || fail
command -v mkdir >/dev/null 2>&1 || fail
command -v rmdir >/dev/null 2>&1 || fail

if [ ! -r "$FOXSTART" ]; then
    FOXSTART=/system/bin/foxstart.sh
fi
[ -r "$FOXSTART" ] || fail
marker_count=0
while IFS= read -r marker_line || [ -n "$marker_line" ]; do
    if [ "$marker_line" = "$READY_MARKER" ]; then
        marker_count=$((marker_count + 1))
    fi
done < "$FOXSTART"
[ "$marker_count" -eq 1 ] || fail

[ -b "$SYSTEM_DEVICE" ] || fail
[ -b "$VENDOR_DEVICE" ] || fail
[ ! -e "$MOUNT_BASE" ] && [ ! -L "$MOUNT_BASE" ] || fail
umask 077
mkdir "$MOUNT_BASE" || fail
base_created=1
mkdir "$SYSTEM_MOUNT" || fail
system_dir_created=1
mkdir "$VENDOR_MOUNT" || fail
vendor_dir_created=1

mount_partition() {
    mount_device=$1
    mount_path=$2
    mount -t erofs -o ro,nodev,nosuid,noexec "$mount_device" "$mount_path" && return 0
    mount -t ext4 -o ro,noload,nodev,nosuid,noexec "$mount_device" "$mount_path"
}

system_mounted=1
mount_partition "$SYSTEM_DEVICE" "$SYSTEM_MOUNT" || fail
vendor_mounted=1
mount_partition "$VENDOR_DEVICE" "$VENDOR_MOUNT" || fail

SYSTEM_BUILD_PROP=$SYSTEM_MOUNT/system/build.prop
VENDOR_BUILD_PROP=$VENDOR_MOUNT/build.prop
[ -f "$SYSTEM_BUILD_PROP" ] && [ -r "$SYSTEM_BUILD_PROP" ] || fail
[ -f "$VENDOR_BUILD_PROP" ] && [ -r "$VENDOR_BUILD_PROP" ] || fail

# Extract exactly one literal property assignment without sourcing build.prop.
read_one_property() {
    property_file=$1
    property_name=$2
    parsed_value=
    property_count=0

    while IFS= read -r property_line || [ -n "$property_line" ]; do
        line_to_parse=${property_line#"${property_line%%[![:space:]]*}"}
        case "$line_to_parse" in
            ''|'#'*) continue ;;
            *=*)
                raw_key=${line_to_parse%%=*}
                normalized_key=${raw_key#"${raw_key%%[![:space:]]*}"}
                normalized_key=${normalized_key%"${normalized_key##*[![:space:]]}"}
                if [ "$normalized_key" = "$property_name" ]; then
                    [ "$raw_key" = "$property_name" ] || return 1
                    property_count=$((property_count + 1))
                    [ "$property_count" -eq 1 ] || return 1
                    parsed_value=${line_to_parse#*=}
                fi
                ;;
            *)
                case "$line_to_parse" in
                    "$property_name"|"$property_name"[[:space:]]*) return 1 ;;
                esac
        esac
    done < "$property_file"

    [ "$property_count" -eq 1 ] && [ -n "$parsed_value" ]
}

valid_release() {
    case "$1" in
        ''|.*|*.|*..*|*[!0-9.]*|99.87.36) return 1 ;;
        *) return 0 ;;
    esac
}

valid_patch_date() {
    patch_date=$1
    case "$patch_date" in
        ????-??-??) ;;
        *) return 1 ;;
    esac
    case "$patch_date" in
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
        *) return 1 ;;
    esac
    [ "$patch_date" != 2099-12-31 ] || return 1

    date_year=${patch_date%%-*}
    date_tail=${patch_date#*-}
    date_month=${date_tail%%-*}
    date_day=${date_tail#*-}
    while [ "${date_year#0}" != "$date_year" ]; do
        date_year=${date_year#0}
    done
    [ -n "$date_year" ] || date_year=0
    while [ "${date_month#0}" != "$date_month" ]; do
        date_month=${date_month#0}
    done
    [ -n "$date_month" ] || date_month=0
    while [ "${date_day#0}" != "$date_day" ]; do
        date_day=${date_day#0}
    done
    [ -n "$date_day" ] || date_day=0

    [ "$date_year" -ge 1 ] && [ "$date_month" -ge 1 ] && [ "$date_month" -le 12 ] || return 1
    case "$date_month" in
        1|3|5|7|8|10|12) month_days=31 ;;
        4|6|9|11) month_days=30 ;;
        2)
            year_number=$((date_year))
            if [ $((year_number % 400)) -eq 0 ] || { [ $((year_number % 4)) -eq 0 ] && [ $((year_number % 100)) -ne 0 ]; }; then
                month_days=29
            else
                month_days=28
            fi
            ;;
        *) return 1 ;;
    esac
    [ "$date_day" -ge 1 ] && [ "$date_day" -le "$month_days" ]
}

read_one_property "$SYSTEM_BUILD_PROP" ro.build.version.release || fail
rom_release=$parsed_value
read_one_property "$SYSTEM_BUILD_PROP" ro.build.version.security_patch || fail
system_patch=$parsed_value
read_one_property "$VENDOR_BUILD_PROP" ro.vendor.build.security_patch || fail
vendor_patch=$parsed_value
valid_release "$rom_release" || fail
valid_patch_date "$system_patch" || fail
valid_patch_date "$vendor_patch" || fail

resetprop ro.build.version.release "$rom_release" >/dev/null 2>&1 || fail
resetprop ro.build.version.security_patch "$system_patch" >/dev/null 2>&1 || fail
resetprop ro.vendor.build.security_patch "$vendor_patch" >/dev/null 2>&1 || fail

actual_value=$(getprop ro.build.version.release 2>/dev/null) || fail
[ "$actual_value" = "$rom_release" ] || fail
actual_value=$(getprop ro.build.version.security_patch 2>/dev/null) || fail
[ "$actual_value" = "$system_patch" ] || fail
actual_value=$(getprop ro.vendor.build.security_patch 2>/dev/null) || fail
[ "$actual_value" = "$vendor_patch" ] || fail

# No mount may remain when KeyMint is allowed to start.
umount "$VENDOR_MOUNT" || fail
vendor_mounted=0
umount "$SYSTEM_MOUNT" || fail
system_mounted=0
rmdir "$VENDOR_MOUNT" || fail
vendor_dir_created=0
rmdir "$SYSTEM_MOUNT" || fail
system_dir_created=0
rmdir "$MOUNT_BASE" || fail
base_created=0

setprop twrp.keymint.props_ready true >/dev/null 2>&1 || fail
gate_state=$(getprop twrp.keymint.props_ready 2>/dev/null) || fail
[ "$gate_state" = true ] || fail

finish 0
