# Android Play Store Publishing

This project is prepared for Play Store release, but a few values still depend on
your production account and private signing key.

## Current Android identity

- Android package / application ID: `com.qurannoor.mobile`
- Firebase Android config file: `android/app/google-services.json`

Important:
- The codebase is now set to `com.qurannoor.mobile`.
- If you change the package name for release, you must create a matching Android
  app in Firebase and replace `android/app/google-services.json`.

## Release signing

The Android Gradle config now supports release signing via:

- `android/key.properties`

Template:

- `android/key.properties.example`

Expected keys:

- `storeFile`
- `storePassword`
- `keyAlias`
- `keyPassword`

If `android/key.properties` is missing, release builds fall back to the debug
signing key so local builds keep working. Do not upload a debug-signed release to
Google Play.

## Generate an upload keystore

Example command:

```bash
keytool -genkeypair \
  -v \
  -keystore ~/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

Then create `android/key.properties`:

```properties
storeFile=/Users/your-name/upload-keystore.jks
storePassword=your-store-password
keyAlias=upload
keyPassword=your-key-password
```

## Build for Google Play

Preferred upload artifact:

```bash
flutter build appbundle --release
```

Output:

- `build/app/outputs/bundle/release/app-release.aab`

## Play Console checklist

Before uploading:

1. Update app version in `pubspec.yaml`
2. Verify the app name, icon, screenshots, and description
3. Verify Firebase works with the final package name
4. Test notifications on a release build
5. Test microphone/recitation features on a release build
6. Test prayer-time fetch and offline fallback on a release build

## Sensitive permissions in this app

This app currently declares:

- `RECORD_AUDIO`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_FINE_LOCATION`
- `POST_NOTIFICATIONS`
- `SCHEDULE_EXACT_ALARM`
- `RECEIVE_BOOT_COMPLETED`

Prepare Play Console disclosures carefully for:

- microphone usage
- location usage
- notification usage
- alarm/reminder behavior

Also complete:

- Data safety
- App content
- Content rating
- Target audience
- Privacy policy

## Recommended final package-name cleanup

For publishing, the project now uses `com.qurannoor.mobile` across:

- `android/app/build.gradle.kts`
- `android/app/google-services.json`
- Android Kotlin package path / `MainActivity.kt`
- `ios/Runner/GoogleService-Info.plist`
- `ios/Runner.xcodeproj/project.pbxproj`
- `macos/Runner/Configs/AppInfo.xcconfig`
- `linux/CMakeLists.txt`

Do that only when you are ready to also update Firebase config files.
