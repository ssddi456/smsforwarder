#!/usr/bin/env bash

source "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/common.sh"

artifacts_dir="${1:-$ARTIFACTS_DIR}"
[[ -d "$artifacts_dir" ]] || fail "Artifact directory not found: $artifacts_dir"

aapt="$(find_build_tool aapt)"

read_package() {
    local apk="$1"
    if [[ -n "$aapt" ]]; then
        "$aapt" dump badging "$apk" 2>/dev/null |
            sed -n "s/^package: name='\([^']*\)'.*/\1/p" |
            head -n 1
        return
    fi

    if command -v apkanalyzer >/dev/null 2>&1; then
        apkanalyzer manifest application-id "$apk" 2>/dev/null
        return
    fi

    fail "Neither aapt nor apkanalyzer is available for APK inspection."
}

verify_apk() {
    local apk="$1"
    local expected="$2"
    local actual

    [[ -f "$apk" ]] || fail "Missing APK: $apk"
    actual="$(read_package "$apk")"
    [[ -n "$actual" ]] || fail "Could not read package ID from $apk."

    if [[ "$actual" != "$expected" ]] && [[ "$actual" != "$expected.debug" ]]; then
        fail "Unexpected package '$actual' in $(basename "$apk"); expected '$expected' or '$expected.debug'."
    fi

    info "$(basename "$apk"): $actual"
}

"$ROOT_DIR/scripts/check-source.sh"
verified_messages=0
verified_smsforwarder=0

for build_type in debug release; do
    messages_apk="$artifacts_dir/messages-$build_type.apk"
    smsforwarder_apk="$artifacts_dir/smsforwarder-$build_type.apk"

    if [[ -f "$messages_apk" ]]; then
        verify_apk "$messages_apk" "org.fossify.messages"
        verified_messages=$((verified_messages + 1))
    fi

    if [[ -f "$smsforwarder_apk" ]]; then
        verify_apk "$smsforwarder_apk" "cn.ppps.forwarder"
        verified_smsforwarder=$((verified_smsforwarder + 1))
    fi
done

((verified_messages > 0)) || fail "No Fossify Messages APK found in $artifacts_dir."
((verified_smsforwarder > 0)) || fail "No SmsForwarder APK found in $artifacts_dir."

info "APK package verification passed."

