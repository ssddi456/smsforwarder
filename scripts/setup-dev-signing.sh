#!/usr/bin/env bash

source "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/common.sh"

keystore_dir="$ROOT_DIR/smsforwarder/keystore"
keystore_file="$keystore_dir/smsforwarder-debug.keystore"
properties_file="$keystore_dir/keystore.properties"

export JAVA_HOME
JAVA_HOME="$(resolve_java_17)"
keytool="$JAVA_HOME/bin/keytool"

[[ -x "$keytool" ]] || fail "keytool not found under $JAVA_HOME."

mkdir -p "$keystore_dir"

if [[ ! -f "$keystore_file" ]]; then
    "$keytool" -genkeypair \
        -keystore "$keystore_file" \
        -storepass android \
        -alias androiddebugkey \
        -keypass android \
        -dname "CN=Android Debug,O=Android,C=US" \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000
fi

printf '%s\n' \
    'keyAlias=androiddebugkey' \
    'keyPassword=android' \
    "storeFile=$keystore_file" \
    'storePassword=android' \
    > "$properties_file"

info "Development signing configured: $properties_file"
info "Use the original production certificate when preserving existing app data."

