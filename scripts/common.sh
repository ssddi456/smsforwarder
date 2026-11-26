#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
ARTIFACTS_DIR="$ROOT_DIR/artifacts"

fail() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

info() {
    printf '%s\n' "$*"
}

java_major() {
    local java_bin="$1/bin/java"
    [[ -x "$java_bin" ]] || return 1
    "$java_bin" -version 2>&1 |
        awk -F '"' '/version/ { print $2; exit }' |
        awk -F. '{ if ($1 == 1) print $2; else print $1 }'
}

resolve_java_17() {
    local candidate="${SMSFORWARDER_JAVA_HOME:-${JAVA_HOME:-}}"

    if [[ -n "$candidate" ]] && [[ "$(java_major "$candidate" 2>/dev/null || true)" == "17" ]]; then
        printf '%s\n' "$candidate"
        return
    fi

    for candidate in \
        /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
        /usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home; do
        if [[ -x "$candidate/bin/java" ]] &&
            [[ "$(java_major "$candidate" 2>/dev/null || true)" == "17" ]]; then
            printf '%s\n' "$candidate"
            return
        fi
    done

    if [[ -x /usr/libexec/java_home ]]; then
        candidate="$(/usr/libexec/java_home -v 17 2>/dev/null || true)"
        if [[ -n "$candidate" ]] && [[ "$(java_major "$candidate" 2>/dev/null || true)" == "17" ]]; then
            printf '%s\n' "$candidate"
            return
        fi
    fi

    fail "JDK 17 is required. Set JAVA_HOME or SMSFORWARDER_JAVA_HOME to a JDK 17 installation."
}

resolve_android_sdk() {
    local candidate
    for candidate in "${ANDROID_SDK_ROOT:-}" "${ANDROID_HOME:-}" "$HOME/Library/Android/sdk"; do
        if [[ -n "$candidate" ]] && [[ -d "$candidate/platforms" ]]; then
            printf '%s\n' "$candidate"
            return
        fi
    done

    fail "Android SDK not found. Set ANDROID_SDK_ROOT or ANDROID_HOME."
}

find_adb() {
    local sdk
    sdk="$(resolve_android_sdk)"
    [[ -x "$sdk/platform-tools/adb" ]] || fail "adb not found under $sdk/platform-tools."
    printf '%s\n' "$sdk/platform-tools/adb"
}

find_build_tool() {
    local tool="$1"
    local sdk
    sdk="$(resolve_android_sdk)"
    find "$sdk/build-tools" -type f -name "$tool" -perm -111 -print 2>/dev/null |
        awk -F/ '{ print $(NF-1) "\t" $0 }' |
        sort -n |
        tail -n 1 |
        cut -f 2
}

capitalize() {
    local value="$1"
    printf '%s%s\n' "$(printf '%s' "${value:0:1}" | tr '[:lower:]' '[:upper:]')" "${value:1}"
}

