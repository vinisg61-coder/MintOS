#!/usr/bin/env bash
#
# Copyright (C) 2023 Salvo Giangreco
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

if [[ "${ROM_BUILD_MODE:-normal}" == "debug" ]]; then
    set +e
    set -E
else
    set -e
fi

#[
source "$SRC_DIR/scripts/utils/module_utils.sh" || exit 1

if IS_ROM_BUILD_DEBUG; then
    CURRENT_MODULE=""
    trap 'status=$?; failed_command=$BASH_COMMAND; RECORD_ROM_BUILD_ERROR "module ${CURRENT_MODULE:-unknown}: command failed (exit $status): $failed_command"' ERR
fi

ADD_MODULE_TREE()
{
    local MODNAME="$1"
    shift

    if ADD_TO_WORK_DIR "$@"; then
        return 0
    fi

    if IS_ROM_BUILD_DEBUG; then
        RECORD_ROM_BUILD_ERROR "module '$MODNAME': failed to add '$3' from '$1' to partition '$2'"
        return 0
    fi
    return 1
}

APPLY_MODULE()
{
    local MODPATH="$1"
    local MODNAME
    local MODAUTH

    if [ ! -d "$MODPATH" ]; then
        LOGE "Folder not found: ${MODPATH//$SRC_DIR\//}"
        RECORD_ROM_BUILD_ERROR "module folder not found: ${MODPATH//$SRC_DIR\//}"
        return 1
    fi

    if [ -d "$MODPATH/$TARGET_SINGLE_SYSTEM_IMAGE" ]; then
        MODPATH="$MODPATH/$TARGET_SINGLE_SYSTEM_IMAGE"
    fi

    if [ ! -f "$MODPATH/module.prop" ]; then
        LOGE "File not found: ${MODPATH//$SRC_DIR\//}/module.prop"
        RECORD_ROM_BUILD_ERROR "module metadata not found: ${MODPATH//$SRC_DIR\//}/module.prop"
        return 1
    elif [ -f "$MODPATH/disable" ]; then
        return 0
    else
        MODNAME="$(grep "^name" "$MODPATH/module.prop" | sed "s/name=//")"
        MODAUTH="$(grep "^author" "$MODPATH/module.prop" | sed "s/author=//" | sed "s/, /, @/")"
    fi

    LOG_STEP_IN "- Processing \"$MODNAME\" by @$MODAUTH"

    if ! grep -q "^SKIPUNZIP=1$" "$MODPATH/customize.sh" 2> /dev/null; then
        if [ -d "$MODPATH/odm" ]; then
            ADD_MODULE_TREE "$MODNAME" "$MODPATH" "odm" "." 0 0 755 "u:object_r:vendor_file:s0"
        fi
        if [ -d "$MODPATH/product" ]; then
            ADD_MODULE_TREE "$MODNAME" "$MODPATH" "product" "." 0 0 755 "u:object_r:system_file:s0"
        fi
        if [ -d "$MODPATH/system" ]; then
            ADD_MODULE_TREE "$MODNAME" "$MODPATH" "system" "." 0 0 755 "u:object_r:system_file:s0"
        fi
        if [ -d "$MODPATH/system_ext" ]; then
            ADD_MODULE_TREE "$MODNAME" "$MODPATH" "system_ext" "." 0 0 755 "u:object_r:system_file:s0"
        fi
        if [ -d "$MODPATH/vendor" ]; then
            ADD_MODULE_TREE "$MODNAME" "$MODPATH" "vendor" "." 0 2000 755 "u:object_r:vendor_file:s0"
        fi
    fi

    if IS_ROM_BUILD_DEBUG; then
        if ! READ_AND_APPLY_PROPS "$MODPATH"; then
            RECORD_ROM_BUILD_ERROR "module '$MODNAME': failed while applying properties"
        fi
    else
        READ_AND_APPLY_PROPS "$MODPATH"
    fi

    if [ "$TARGET_SINGLE_SYSTEM_IMAGE" != "self" ]; then
        if [ -d "$MODPATH/smali" ]; then
            while IFS= read -r f; do
                if IS_ROM_BUILD_DEBUG; then
                    if ! APPLY_SMALI_PATCHES "$MODPATH/smali" "$f"; then
                        RECORD_ROM_BUILD_ERROR "module '$MODNAME': failed while processing patches for $f"
                    fi
                else
                    APPLY_SMALI_PATCHES "$MODPATH/smali" "$f"
                fi
            done < <(find "$MODPATH/smali" -type d \( -name "*.apk" -o -name "*.jar" \) | sed "s|$MODPATH/smali/||")
        fi
    fi

    if [ -f "$MODPATH/customize.sh" ]; then
        RUN_MODULE_CUSTOMIZE "$MODPATH/customize.sh" "$MODNAME"
    fi

    LOG_STEP_OUT

    return 0
}

RUN_MODULE_CUSTOMIZE()
{
    local CUSTOMIZE_SCRIPT="$1"
    local CUSTOMIZE_MODULE="$2"
    local CUSTOMIZE_STATUS
    if IS_ROM_BUILD_DEBUG; then
        (
            set +e
            set -E
            export ROM_BUILD_CURRENT_MODULE="$CUSTOMIZE_MODULE"
            trap 'status=$?; failed_command=$BASH_COMMAND; RECORD_ROM_BUILD_ERROR "module $ROM_BUILD_CURRENT_MODULE customize.sh command failed (exit $status): $failed_command"' ERR
            . "$CUSTOMIZE_SCRIPT"
        )
        CUSTOMIZE_STATUS=$?
        if [ "$CUSTOMIZE_STATUS" -ne 0 ]; then
            RECORD_ROM_BUILD_ERROR "module '$CUSTOMIZE_MODULE': customize.sh exited with status $CUSTOMIZE_STATUS"
        fi
        return 0
    fi

    . "$CUSTOMIZE_SCRIPT"
}

APPLY_SMALI_PATCHES()
{
    local PATCHES_PATH="$1"
    local TARGET="$2"

    local PARTITION
    PARTITION="$(cut -d "/" -f 1 -s <<< "$TARGET")"

    if ! IS_VALID_PARTITION_NAME "$PARTITION"; then
        LOGE "\"$PARTITION\" is not a valid partition name"
        if IS_ROM_BUILD_DEBUG; then
            RECORD_ROM_BUILD_ERROR "invalid partition '$PARTITION' while applying patches for $TARGET"
            return 0
        fi
        return 1
    fi

    while IFS= read -r p; do
        local FILE="$TARGET"
        [[ "$PARTITION" != "system" ]] && FILE="$(cut -d "/" -f 2- -s <<< "$FILE")"

        if IS_ROM_BUILD_DEBUG; then
            if ! APPLY_PATCH "$PARTITION" "$FILE" "$p"; then
                RECORD_ROM_BUILD_ERROR "patch failed: ${p//$SRC_DIR\//} -> /$PARTITION/$FILE"
            fi
        else
            APPLY_PATCH "$PARTITION" "$FILE" "$p"
        fi
    done < <(find "$PATCHES_PATH/$TARGET" -type f -name "*.patch" | sort -n)

    return 0
}

READ_AND_APPLY_PROPS()
{
    local MODPATH="$1"
    local PARTITION

    while IFS= read -r f; do
        PARTITION=$(basename "$f" | sed "s/.prop//")
        IS_VALID_PARTITION_NAME "$PARTITION" || continue

        while read -r l; do
            [[ "$l" == "#"* ]] && continue
            [ ! "$l" ] && continue

            if grep -q -F "=" <<< "$l"; then
                if [ ! "$(cut -d "=" -f 2- -s <<< "$l")" ]; then
                    if IS_ROM_BUILD_DEBUG; then
                        if ! SET_PROP "$PARTITION" "$(cut -d "=" -f 1 -s <<< "$l")" --delete; then
                            RECORD_ROM_BUILD_ERROR "failed to delete property in ${f//$SRC_DIR\//}: $l"
                        fi
                    else
                        SET_PROP "$PARTITION" "$(cut -d "=" -f 1 -s <<< "$l")" --delete
                    fi
                else
                    if IS_ROM_BUILD_DEBUG; then
                        if ! SET_PROP "$PARTITION" "$(cut -d "=" -f 1 -s <<< "$l")" "$(cut -d "=" -f 2- -s <<< "$l")"; then
                            RECORD_ROM_BUILD_ERROR "failed to set property in ${f//$SRC_DIR\//}: $l"
                        fi
                    else
                        SET_PROP "$PARTITION" "$(cut -d "=" -f 1 -s <<< "$l")" "$(cut -d "=" -f 2- -s <<< "$l")"
                    fi
                fi
            else
                LOGE "Malformed string in $f: \"$l\""
                if IS_ROM_BUILD_DEBUG; then
                    RECORD_ROM_BUILD_ERROR "malformed property in ${f//$SRC_DIR\//}: $l"
                else
                    return 1
                fi
            fi
        done < "$f"
    done < <(find "$MODPATH" -maxdepth 1 -type f -name "*.prop")

    return 0
}
#]

if [ "$#" != "1" ]; then
    echo "Usage: apply_modules <folder>" >&2
    exit 1
elif [ ! -d "$1" ]; then
    LOGE "Folder not found: ${1//$SRC_DIR\//}"
    exit 1
fi

while IFS= read -r f; do
    CURRENT_MODULE="${f//$SRC_DIR\//}"
    if IS_ROM_BUILD_DEBUG; then
        APPLY_MODULE "$f"
        MODULE_STATUS=$?
        if [ "$MODULE_STATUS" -ne 0 ]; then
            RECORD_ROM_BUILD_ERROR "module failed: ${f//$SRC_DIR\//}"
        fi
    else
        APPLY_MODULE "$f"
    fi
done < <(find "$1" -mindepth 1 -maxdepth 1 -type d | sort)

exit 0
