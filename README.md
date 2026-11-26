# Fossify Messages + SmsForwarder

This repository combines the user-facing SMS ability of
[Fossify Messages](https://github.com/FossifyOrg/Messages) with the forwarding
engine of [SmsForwarder](https://github.com/pppscn/smsforwarder). It deliberately
does not merge their source code or databases.

## Architecture

Fossify is the only default SMS application. It receives the Android
`SMS_DELIVER` broadcast, displays conversations, sends replies, and handles MMS.
SmsForwarder remains a regular application and receives the `SMS_RECEIVED`
broadcast available to apps with SMS permission. It then applies its existing
rules, templates, logs, and sender channels.

| Application | Package | Android role | Incoming action |
| --- | --- | --- | --- |
| Fossify Messages | `org.fossify.messages` | Default SMS app (`ROLE_SMS`) | `SMS_DELIVER` |
| SmsForwarder | `cn.ppps.forwarder` | None | `SMS_RECEIVED` |

The apps have separate signatures, settings, databases, release cycles, and
launchers. There is no shared ContentProvider, broadcast protocol, or database.

## Source layout

```text
messages/       Fossify Messages, independent Gradle project
smsforwarder/   SmsForwarder, independent Gradle project
scripts/        Build, install, verification, and smoke-test helpers
artifacts/      Stable output copies from scripts/build.sh
UPSTREAMS.md    Pinned source revisions and update procedure
```

See `UPSTREAMS.md` for exact revisions and upstream update instructions.

## Build requirements

- JDK 17. Set `JAVA_HOME` or make JDK 17 discoverable through
  `/usr/libexec/java_home -v 17` on macOS.
- Android SDK with platform 36 and platform-tools.
- Network access for the first dependency and Gradle-wrapper download.
- Bash and either an emulator or an Android 11+ device for installation.

The scripts locate the Android SDK from `ANDROID_SDK_ROOT`, `ANDROID_HOME`, or
the default macOS SDK path.

## Build and verify

Build debug APKs and copy the universal outputs to `artifacts/`:

```bash
scripts/build.sh debug
scripts/verify-apks.sh
```

The first debug build automatically creates a local, Git-ignored SmsForwarder
debug signing key through `scripts/setup-dev-signing.sh`. This key is suitable
only for development and must not be used for an update that needs to retain an
existing installation's data.

Build release APKs:

```bash
scripts/build.sh release
scripts/verify-apks.sh
```

`scripts/build.sh` accepts `debug` or `release` as its first argument and
`all`, `messages`, or `smsforwarder` as its optional second argument.

### Signing

Fossify reads either `messages/keystore.properties` or the
`SIGNING_KEY_ALIAS`, `SIGNING_KEY_PASSWORD`, `SIGNING_STORE_FILE`, and
`SIGNING_STORE_PASSWORD` environment variables. A release build is unsigned
when none are configured.

SmsForwarder reads `smsforwarder/keystore/keystore.properties` with
`keyAlias`, `keyPassword`, `storeFile`, and `storePassword`.

To preserve existing SmsForwarder rules, sender channels, logs, and history,
the release APK must keep the `cn.ppps.forwarder` application ID and be signed
with the same certificate as the installed SmsForwarder version. Android does
not allow an in-place update with a different certificate.

All local signing files are ignored by Git.

To prepare the local debug key explicitly:

```bash
scripts/setup-dev-signing.sh
```

The Fossify debug package (`org.fossify.messages.debug`) can coexist with the
release package (`org.fossify.messages`). On a production device, keep only the
release package and explicitly select it as the default SMS app. SmsForwarder
uses the same application ID for debug and release, so only one of those builds
can be installed at a time.

## Install

Connect one Android 11+ device or start an emulator:

```bash
scripts/install.sh debug
```

For release artifacts, use:

```bash
scripts/install.sh release
```

If more than one device is connected, set `ANDROID_SERIAL` to the intended
device.

## First-time device setup

1. Open Fossify and accept the system prompt making it the default SMS app.
2. Grant Fossify SMS, contacts, and notification permissions.
3. Confirm in Android settings that Fossify is the default SMS app.
4. Open SmsForwarder, grant notification and SMS permissions, then enable
   **Forward SMS broadcasts** (`转发短信广播`).
5. Configure and test the required forwarding rules and sender channels.
6. Allow SmsForwarder to autostart and remove it from battery optimization on
   vendor ROMs. Some Chinese OEMs also require disabling verification-code
   protection for the forwarding app.
7. Never set SmsForwarder as the default SMS app in this deployment model.

On emulators, send a test text with:

```bash
scripts/smoke-test.sh 10086 "integration test"
```

The script checks the installed packages and default-SMS role holder, sends the
emulator SMS, and prints useful post-test commands. Check Fossify for exactly
one displayed message and SmsForwarder for exactly one matching forwarding log.

## Acceptance checks

- Android 11, 13, and 16 devices show both packages with stable package IDs.
- Fossify is the sole default SMS app; SmsForwarder is not.
- Normal, long, multipart, non-ASCII, and dual-SIM text messages appear once in
  Fossify and produce at most one matching forward.
- Unmatched messages, disabled forwarding, quiet hours, duplicate suppression,
  sender failure, retry, and reboot behavior follow existing SmsForwarder
  settings.
- Each configured sender channel can complete a test send.
- Over-installing a new SmsForwarder build with the same certificate retains
  all rules, sender settings, logs, and history.

## Scope and limitations

- Text SMS is the forwarding acceptance target.
- MMS and RCS remain normal Fossify responsibilities and are not promised to be
  forwarded by SmsForwarder's non-default-app path.
- SmsForwarder's existing channels and rules are not rewritten or reduced.
- OEM background restrictions can still interrupt delivery. Keep notifications,
  autostart, and background execution enabled.

