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

set +e
set -E

#[
source "$SRC_DIR/scripts/utils/module_utils.sh" || exit 1

CURRENT_MODULE=""
trap 'status=$?; failed_command=$BASH_COMMAND; RECORD_ROM_BUILD_ERROR "module ${CURRENT_MODULE:-unknown}: command failed (exit $status): $failed_command"' ERR

APPLY_MODULE()
{
    local MODPATH="$1"
    local MODNAME
    local MODAUTH

    if [ ! -d "$MODPATH" ]; then
        LOGE "Folder not found: ${MODPATH//$SRC_DIR\//}"
        return 1
    fi

    if [ -d "$MODPATH/$TARGET_SINGLE_SYSTEM_IMAGE" ]; then
        MODPATH="$MODPATH/$TARGET_SINGLE_SYSTEM_IMAGE"
    fi

    if [ ! -f "$MODPATH/module.prop" ]; then
        LOGE "File not found: ${MODPATH//$SRC_DIR\//}/module.prop"
        return 1
    elif [ -f "$MODPATH/disable" ]; then
        return 0
    else
        MODNAME="$(grep "^name" "$MODPATH/module.prop" | sed "s/name=//")"
        MODAUTH="$(grep "^author" "$MODPATH/module.prop" | sed "s/author=//" | sed "s/, /, @/")"
    fi

    LOG_STEP_IN "- Processing \"$MODNAME\" by @$MODAUTH"

    if ! grep -q "^SKIPUNZIP=1$" "$MODPATH/customize.sh" 2> /dev/null; then
        [ ! -d "$MODPATH/odm" ] || ADD_TO_WORK_DIR "$MODPATH" "odm" "." 0 0 755 "u:object_r:vendor_file:s0" || RECORD_ROM_BUILD_ERROR "module '$MODNAME': failed to copy odm contents"
        [ ! -d "$MODPATH/product" ] || ADD_TO_WORK_DIR "$MODPATH" "product" "." 0 0 755 "u:object_r:system_file:s0" || RECORD_ROM_BUILD_ERROR "module '$MODNAME': failed to copy product contents"
        [ ! -d "$MODPATH/system" ] || ADD_TO_WORK_DIR "$MODPATH" "system" "." 0 0 755 "u:object_r:system_file:s0" || RECORD_ROM_BUILD_ERROR "module '$MODNAME': failed to copy system contents"
        [ ! -d "$MODPATH/system_ext" ] || ADD_TO_WORK_DIR "$MODPATH" "system_ext" "." 0 0 755 "u:object_r:system_file:s0" || RECORD_ROM_BUILD_ERROR "module '$MODNAME': failed to copy system_ext contents"
        [ ! -d "$MODPATH/vendor" ] || ADD_TO_WORK_DIR "$MODPATH" "vendor" "." 0 2000 755 "u:object_r:vendor_file:s0" || RECORD_ROM_BUILD_ERROR "module '$MODNAME': failed to copy vendor contents"
    fi

    if ! READ_AND_APPLY_PROPS "$MODPATH"; then
        RECORD_ROM_BUILD_ERROR "module '$MODNAME': failed while applying properties"
    fi

    if [ "$TARGET_SINGLE_SYSTEM_IMAGE" != "self" ]; then
        if [ -d "$MODPATH/smali" ]; then
            while IFS= read -r f; do
                if ! APPLY_SMALI_PATCHES "$MODPATH/smali" "$f"; then
                    RECORD_ROM_BUILD_ERROR "module '$MODNAME': failed while processing patches for $f"
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
    local RESTORE_ERREXIT=false

    [[ "$-" == *e* ]] && RESTORE_ERREXIT=true
    set +e
    (
        set +e
        set -E
        export ROM_BUILD_CURRENT_MODULE="$CUSTOMIZE_MODULE"
        trap 'status=$?; failed_command=$BASH_COMMAND; RECORD_ROM_BUILD_ERROR "module $ROM_BUILD_CURRENT_MODULE customize.sh command failed (exit $status): $failed_command"' ERR
        . "$CUSTOMIZE_SCRIPT"
    )
    CUSTOMIZE_STATUS=$?
    $RESTORE_ERREXIT && set -e

    if [ "$CUSTOMIZE_STATUS" -ne 0 ]; then
        RECORD_ROM_BUILD_ERROR "module '$CUSTOMIZE_MODULE': customize.sh exited with status $CUSTOMIZE_STATUS"
    fi
    return 0
}

APPLY_SMALI_PATCHES()
{
    local PATCHES_PATH="$1"
    local TARGET="$2"

    local PARTITION
    PARTITION="$(cut -d "/" -f 1 -s <<< "$TARGET")"

    if ! IS_VALID_PARTITION_NAME "$PARTITION"; then
        LOGE "\"$PARTITION\" is not a valid partition name"
        RECORD_ROM_BUILD_ERROR "invalid partition '$PARTITION' while applying patches for $TARGET"
        return 0
    fi

    while IFS= read -r p; do
        local FILE="$TARGET"
        [[ "$PARTITION" != "system" ]] && FILE="$(cut -d "/" -f 2- -s <<< "$FILE")"

        if ! APPLY_PATCH "$PARTITION" "$FILE" "$p"; then
            RECORD_ROM_BUILD_ERROR "patch failed: ${p//$SRC_DIR\//} -> /$PARTITION/$FILE"
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
                    if ! SET_PROP "$PARTITION" "$(cut -d "=" -f 1 -s <<< "$l")" --delete; then
                        RECORD_ROM_BUILD_ERROR "failed to delete property in ${f//$SRC_DIR\//}: $l"
                    fi
                else
                    if ! SET_PROP "$PARTITION" "$(cut -d "=" -f 1 -s <<< "$l")" "$(cut -d "=" -f 2- -s <<< "$l")"; then
                        RECORD_ROM_BUILD_ERROR "failed to set property in ${f//$SRC_DIR\//}: $l"
                    fi
                fi
            else
                LOGE "Malformed string in $f: \"$l\""
                RECORD_ROM_BUILD_ERROR "malformed property in ${f//$SRC_DIR\//}: $l"
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
    APPLY_MODULE "$f"
    MODULE_STATUS=$?
    if [ "$MODULE_STATUS" -ne 0 ]; then
        RECORD_ROM_BUILD_ERROR "module failed: ${f//$SRC_DIR\//}"
    fi
done < <(find "$1" -mindepth 1 -maxdepth 1 -type d | sort)

exit 0
