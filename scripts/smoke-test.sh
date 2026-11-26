#!/usr/bin/env bash

source "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/common.sh"

number="${1:-10086}"
message="${2:-integration test}"
adb="$(find_adb)"

serial="${ANDROID_SERIAL:-}"
if [[ -z "$serial" ]]; then
    devices="$("$adb" devices | awk 'NR > 1 && $2 == "device" { print $1 }')"
    count="$(printf '%s\n' "$devices" | sed '/^$/d' | wc -l | tr -d ' ')"
    [[ "$count" == "1" ]] || fail "Use ANDROID_SERIAL when zero or multiple devices are connected."
    serial="$devices"
fi

installed_packages="$("$adb" -s "$serial" shell pm list packages)"
[[ "$installed_packages" == *"org.fossify.messages"* ]] ||
    fail "Fossify Messages is not installed."
[[ "$installed_packages" == *"cn.ppps.forwarder"* ]] ||
    fail "SmsForwarder is not installed."

role_holders="$("$adb" -s "$serial" shell cmd role get-role-holders android.app.role.SMS 2>/dev/null || true)"
if [[ "$role_holders" != *"org.fossify.messages"* ]]; then
    fail "Fossify does not hold ROLE_SMS. Current holder(s): ${role_holders:-none}"
fi
if [[ "$role_holders" == *"cn.ppps.forwarder"* ]]; then
    fail "SmsForwarder must not hold ROLE_SMS in this deployment model."
fi

info "Default SMS role holder: $role_holders"
info "Sending emulator SMS from $number..."
"$adb" -s "$serial" emu sms send "$number" "$message"

info "Verify that Fossify shows exactly one message and SmsForwarder records at most one matching forward."
info "Useful checks:"
info "  adb -s $serial logcat -d | rg 'SmsReceiver|SendWorker|SmsForwarder'"
info "  adb -s $serial shell dumpsys role"

