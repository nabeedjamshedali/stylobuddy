# Runbook — Publishing Remote Config (F25)

> Firebase project `stylobuddy-b7e46`. Template: `scripts/remoteconfig.template.json`.
> Feature doc: `docs/features/F25-analytics-remote-config.md`. Nothing in the repo publishes
> this automatically; `firebase.json` deliberately has no `remoteconfig` entry.

## Parameters

| Key | Type | In-app default | Effect |
|---|---|---|---|
| `min_supported_version` | String | `''` | installed `versionName` < value -> blocking "Update required" |
| `latest_version` | String | `''` | installed < value -> dismissible "A new version…" banner |
| `ai_stylist_enabled` | Boolean | `false` | reserved, no consumer yet |
| `premium_enabled` | Boolean | `false` | reserved, no consumer yet |
| `maintenance_message` | String | `''` | non-blank -> dismissible banner with the text |

Versions compare as dotted integers (`1.2.10 > 1.2.9`); `+build` and `-pre` suffixes are
ignored, so raising the floor needs a new `versionName` in `pubspec.yaml`
(`version: X.Y.Z+N`), not only a new build number. An empty or malformed version string never
blocks anyone (fail-open).

## First publish (template == in-app defaults, changes nothing for users)

Option A, Firebase CLI (preferred):

```bash
firebase login                                   # or GOOGLE_APPLICATION_CREDENTIALS=<service account json>
firebase remoteconfig:get --project stylobuddy-b7e46 -o /tmp/rc-before.json   # backup current
# temporarily point firebase.json at the template, deploy only remote config, then revert:
#   "remoteconfig": { "template": "scripts/remoteconfig.template.json" }
firebase deploy --only remoteconfig --project stylobuddy-b7e46
firebase remoteconfig:versions:list --project stylobuddy-b7e46 --limit 3
```

Option B, REST (no firebase.json change):

```bash
TOKEN=$(gcloud auth print-access-token)          # account/service account with Remote Config Admin
# Fetch the current ETag first so a concurrent console edit is not silently overwritten.
ETAG=$(curl -sS -D - -o /dev/null -H "Authorization: Bearer $TOKEN" \
  https://firebaseremoteconfig.googleapis.com/v1/projects/stylobuddy-b7e46/remoteConfig \
  | awk -F': ' 'tolower($1)=="etag"{print $2}' | tr -d '\r')
curl -sS -X PUT \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json; UTF-8" \
  -H "If-Match: $ETAG" \
  --data @scripts/remoteconfig.template.json \
  https://firebaseremoteconfig.googleapis.com/v1/projects/stylobuddy-b7e46/remoteConfig
```

Add `?validateOnly=true` to the URL for a dry run first.

## Forcing an update

1. Ship the fixed build to Play and confirm it is live for 100% of the track.
2. Set `latest_version` to the new `versionName` first (soft nudge) and wait a day if possible.
3. Set `min_supported_version` to the oldest version you still accept (e.g. `1.1.0`). Never set
   it above the version that is actually live on Play, or users are blocked with nothing to
   update to.
4. Publish. Devices pick it up on the next cold start after their fetch interval (1 h in
   release; a device that fetched a wrong floor re-checks within the hour once you roll it back), and every later cold start applies it before any network call.

Test first, not on everyone: the app sets no user properties, so either use a separate
Firebase test project, or add a conditional value whose condition only a test phone matches
(e.g. `device.language in ['is-IS']` with the test phone set to that locale). F25-A45 is this
check.

## Rollback

```bash
firebase remoteconfig:versions:list --project stylobuddy-b7e46
firebase remoteconfig:rollback --project stylobuddy-b7e46 --version-number <N>
```

A device that already shows "Update required" keeps it until the app is restarted after a
successful fetch of the rolled-back value.

## Never

- Put secrets in any parameter (every client can read all values).
- Change a key name: the app only reads the five keys above.
