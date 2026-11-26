#!/usr/bin/env bash

source "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/common.sh"

build_type="${1:-debug}"
target="${2:-all}"

case "$build_type" in
    debug|release) ;;
    *)
        fail "usage: scripts/build.sh [debug|release] [all|messages|smsforwarder]"
        ;;
esac

case "$target" in
    all|messages|smsforwarder) ;;
    *)
        fail "usage: scripts/build.sh [debug|release] [all|messages|smsforwarder]"
        ;;
esac

export JAVA_HOME
JAVA_HOME="$(resolve_java_17)"
export ANDROID_SDK_ROOT
ANDROID_SDK_ROOT="$(resolve_android_sdk)"
export ANDROID_HOME="$ANDROID_SDK_ROOT"

mkdir -p "$ARTIFACTS_DIR"

copy_first_apk() {
    local source_dir="$1"
    local destination="$2"
    local preferred_pattern="${3:-}"
    local selected=""

    [[ -d "$source_dir" ]] || fail "APK output directory not found: $source_dir"

    if [[ -n "$preferred_pattern" ]]; then
        selected="$(find "$source_dir" -maxdepth 1 -type f -name "$preferred_pattern" -print | sort | tail -n 1)"
    fi

    if [[ -z "$selected" ]]; then
        selected="$(find "$source_dir" -maxdepth 1 -type f -name '*.apk' -print | sort | tail -n 1)"
    fi

    [[ -n "$selected" ]] || fail "No APK found in $source_dir."
    cp -f "$selected" "$destination"
    info "APK: $destination"
}

build_messages() {
    local capital
    capital="$(capitalize "$build_type")"
    info "Building Fossify Messages ($build_type)..."
    (
        cd "$ROOT_DIR/messages"
        ./gradlew --no-daemon ":app:assembleFoss$capital"
    )
    copy_first_apk \
        "$ROOT_DIR/messages/app/build/outputs/apk/foss/$build_type" \
        "$ARTIFACTS_DIR/messages-$build_type.apk"
}

build_smsforwarder() {
    local capital
    capital="$(capitalize "$build_type")"
    if [[ "$build_type" == "debug" ]] &&
        [[ ! -f "$ROOT_DIR/smsforwarder/keystore/keystore.properties" ]]; then
        "$ROOT_DIR/scripts/setup-dev-signing.sh"
    fi
    info "Building SmsForwarder ($build_type)..."
    (
        cd "$ROOT_DIR/smsforwarder"
        sh ./gradlew --no-daemon ":app:assemble$capital"
    )
    copy_first_apk \
        "$ROOT_DIR/smsforwarder/app/build/outputs/apk/$build_type" \
        "$ARTIFACTS_DIR/smsforwarder-$build_type.apk" \
        '*universal*.apk'
}

case "$target" in
    all)
        build_messages
        build_smsforwarder
        ;;
    messages)
        build_messages
        ;;
    smsforwarder)
        build_smsforwarder
        ;;
esac

info "Build complete: $build_type ($target)"

