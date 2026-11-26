# Upstream baselines

This repository vendors two complete upstream source trees without changing their
application code. Each tree remains an independent Gradle project.

| Local directory | Upstream repository | Pinned commit | Imported |
| --- | --- | --- | --- |
| `messages/` | https://github.com/FossifyOrg/Messages | `333d316fe4425a95417707519ec4097a05dcfadd` | 2026-11-26 |
| `smsforwarder/` | https://github.com/pppscn/smsforwarder | `a142f9270624e96b15ecfae53035581354fb6434` | 2026-11-26 |

## Updating an upstream snapshot

1. Fetch the desired upstream revision into a temporary checkout.
2. Replace only the matching local directory, excluding the upstream `.git`
   metadata.
3. Update the commit and import date in this file.
4. Run `scripts/check-source.sh`.
5. Build both applications and repeat the end-to-end checks in `README.md`.

Do not merge both projects into one Gradle build. Their Gradle, Android Gradle
Plugin, Kotlin, package, database, and resource models are intentionally kept
separate.

