# Release playbook

Steps to set up and run releases of DIF Pass for Android. Everything here
that touches a secret (keystore, service account) must be done by a human,
never pasted into a chat or committed to the repo.

## One-time setup

### 1. Generate the release keystore (local machine, not in CI)

Run this yourself in a terminal you trust - never share the output or paste
the passwords anywhere:

```bash
keytool -genkey -v -keystore dif-pass-release.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias dif-pass
```

Keep `dif-pass-release.jks` and the two passwords (keystore + key) somewhere
safe (password manager, encrypted backup). Losing this file means Google
Play can never accept an update signed the same way again.

For local release builds, create `android/key.properties` (gitignored):

```properties
storePassword=<keystore password>
keyPassword=<key password>
keyAlias=dif-pass
storeFile=keystore.jks
```

and copy the `.jks` file to `android/app/keystore.jks`.

### 2. GitHub repository secrets

Add these under Settings > Secrets and variables > Actions:

| Secret | Value |
|---|---|
| `KEYSTORE_BASE64` | `base64 -w0 dif-pass-release.jks` output |
| `KEYSTORE_PASSWORD` | the keystore password |
| `KEY_PASSWORD` | the key password |
| `KEY_ALIAS` | `dif-pass` |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | see step 4 |

### 3. Google Play Console - create the app entry

The Play Developer API cannot create an app or complete its first release;
this must be done once through the Play Console web UI:

1. Create the app (package `com.difcorporation.difpass`).
2. Fill in the store listing, content rating questionnaire, and data safety
   form - Play blocks any release, including via the API, until these are
   complete.
3. Manually upload one AAB (built locally via `flutter build appbundle`) to
   the internal testing track. The API can only update an app that already
   has at least one existing release.

### 4. Service account for automated uploads

1. In Google Cloud Console, create a service account in the project linked
   to your Play Console account.
2. Grant it a JSON key, download it.
3. In Play Console > Users and permissions, invite that service account
   with "Release apps to testing tracks" permission (add production
   permission only once you trust the pipeline).
4. Paste the JSON content into the `PLAY_STORE_SERVICE_ACCOUNT_JSON` secret.

## Day-to-day usage

- **Bump the version**: run the "Bump app version" workflow (patch/minor/
  major) - it edits `pubspec.yaml` and pushes the commit.
- **Build a release**: push to the `release` branch, or run the "Build
  release" workflow manually. It builds the signed APK and AAB and
  publishes them as a GitHub Release tagged `vX.Y.Z`.
- **Publish to Play Store**: run the "Deploy to Play Store" workflow,
  choosing the release tag and the track (internal/alpha/beta/production).
  Production requires typing `PRODUCTION` in the confirmation field.

## Known limitation

The app icon and splash image currently come from a low-resolution
moodboard crop (see `assets/brand/README.md`) - fine for internal/test
builds, but re-run `fvm dart run flutter_launcher_icons` and
`fvm dart run flutter_native_splash:create` once a real 512x512+ (ideally
1024x1024) export of the logo exists, before a production Play Store
submission.
