#!/usr/bin/env bash

source "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/common.sh"

build_type="${1:-debug}"
case "$build_type" in
    debug|release) ;;
    *)
        fail "usage: scripts/install.sh [debug|release]"
        ;;
esac

messages_apk="$ARTIFACTS_DIR/messages-$build_type.apk"
smsforwarder_apk="$ARTIFACTS_DIR/smsforwarder-$build_type.apk"

if [[ ! -f "$messages_apk" ]] || [[ ! -f "$smsforwarder_apk" ]]; then
    info "Artifacts are missing; building both applications first."
    "$ROOT_DIR/scripts/build.sh" "$build_type" all
fi

"$ROOT_DIR/scripts/verify-apks.sh" "$ARTIFACTS_DIR"

if [[ "$build_type" == "release" ]]; then
    apksigner="$(find_build_tool apksigner)"
    [[ -n "$apksigner" ]] || fail "apksigner not found in the Android build-tools."
    "$apksigner" verify "$messages_apk" >/dev/null 2>&1 ||
        fail "Fossify release APK is unsigned. Configure the Fossify production signing key first."
    "$apksigner" verify "$smsforwarder_apk" >/dev/null 2>&1 ||
        fail "SmsForwarder release APK is unsigned."
fi

adb="$(find_adb)"
mapfile_compat() {
    local line
    while IFS= read -r line; do
        [[ -n "$line" ]] && printf '%s\n' "$line"
    done
}

serial="${ANDROID_SERIAL:-}"
if [[ -z "$serial" ]]; then
    devices="$(mapfile_compat <<< "$("$adb" devices | awk 'NR > 1 && $2 == "device" { print $1 }')")"
    count="$(printf '%s\n' "$devices" | sed '/^$/d' | wc -l | tr -d ' ')"
    [[ "$count" != "0" ]] || fail "No online Android device or emulator found."
    [[ "$count" == "1" ]] || fail "Multiple devices are connected. Set ANDROID_SERIAL."
    serial="$devices"
fi

info "Installing to $serial..."
"$adb" -s "$serial" install -r "$messages_apk"
"$adb" -s "$serial" install -r "$smsforwarder_apk"

role_holders="$("$adb" -s "$serial" shell cmd role get-role-holders android.app.role.SMS 2>/dev/null || true)"
info "Current default SMS role holder(s): ${role_holders:-unknown}"
info "Open Fossify first and accept the default-SMS prompt. Keep SmsForwarder non-default."

