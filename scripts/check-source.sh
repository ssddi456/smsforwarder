#!/usr/bin/env bash

source "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/common.sh"

require_text() {
    local file="$1"
    local text="$2"
    rg -q --fixed-strings "$text" "$file" || fail "Expected '$text' in $file."
}

reject_text() {
    local directory="$1"
    local text="$2"
    if rg -q --fixed-strings "$text" "$directory"; then
        fail "Unexpected '$text' found under $directory."
    fi
}

[[ -d "$ROOT_DIR/messages/app" ]] || fail "Fossify source tree is missing."
[[ -d "$ROOT_DIR/smsforwarder/app" ]] || fail "SmsForwarder source tree is missing."

require_text "$ROOT_DIR/messages/gradle.properties" "APP_ID=org.fossify.messages"
require_text "$ROOT_DIR/smsforwarder/app/build.gradle" 'applicationId "cn.ppps.forwarder"'

require_text "$ROOT_DIR/messages/app/src/main/AndroidManifest.xml" "android.provider.Telephony.SMS_DELIVER"
require_text "$ROOT_DIR/messages/app/src/main/kotlin/org/fossify/messages/activities/MainActivity.kt" "RoleManager.ROLE_SMS"

require_text "$ROOT_DIR/smsforwarder/app/src/main/AndroidManifest.xml" "android.permission.RECEIVE_SMS"
require_text "$ROOT_DIR/smsforwarder/app/src/main/AndroidManifest.xml" "android.provider.Telephony.SMS_RECEIVED"
require_text "$ROOT_DIR/smsforwarder/app/src/main/kotlin/cn/ppps/forwarder/receiver/SmsReceiver.kt" "SMS_RECEIVED_ACTION"
reject_text "$ROOT_DIR/smsforwarder/app/src/main" "RoleManager.ROLE_SMS"

require_text "$ROOT_DIR/UPSTREAMS.md" "333d316fe4425a95417707519ec4097a05dcfadd"
require_text "$ROOT_DIR/UPSTREAMS.md" "a142f9270624e96b15ecfae53035581354fb6434"

info "Source integration contract verified."

