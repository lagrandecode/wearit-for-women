# Comprehensive Google Sign-In Setup Guide

This guide will walk you through setting up Google Sign-In for both iOS and Android platforms.

## Prerequisites

- Firebase project created
- Flutter app configured with Firebase
- Google account with access to Firebase Console
- Apple Developer account (for iOS)
- Google Cloud Console access

---

## Part 1: Firebase Console Configuration

### Step 1: Enable Google Sign-In in Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **wearit-9b76f**
3. Navigate to **Authentication** → **Sign-in method**
4. Find **Google** in the list
5. Click on **Google** to open settings
6. Toggle **Enable** to ON
7. Enter a **Project support email** (your email)
8. Click **Save**

### Step 2: Verify iOS App Configuration

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll to **Your apps** section
3. Find your **iOS app** with bundle ID: `com.lagrangecode.wearit`
4. Verify the following:
   - **Bundle ID**: `com.lagrangecode.wearit` ✅
   - **App ID**: `1:45077489966:ios:36b9a725b46a855521f2bf` ✅
   - **GoogleService-Info.plist** is downloaded and in your project ✅

### Step 3: Verify Android App Configuration

1. In the same **Project Settings** page
2. Find your **Android app** with package name: `com.lagrangecode.wearit`
3. Verify the following:
   - **Package name**: `com.lagrangecode.wearit` ✅
   - **App ID**: `1:45077489966:android:ddbb7794ecdfbe8521f2bf` ✅
   - **google-services.json** is in `android/app/` ✅

### Step 4: Add SHA-1 Fingerprint (Android Only)

**Why?** Google Sign-In requires SHA-1 fingerprint for Android to verify your app.

#### Get Your SHA-1 Fingerprint:

**For Debug (Development):**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

**Output should show:**
```
SHA1: 16:C7:66:7B:38:95:0B:0D:12:3B:6B:B5:90:E8:00:CD:9E:0B:FC:F7
```

#### Add to Firebase Console:

1. Firebase Console → **Project Settings**
2. Select your **Android app**
3. Scroll to **SHA certificate fingerprints**
4. Click **Add fingerprint**
5. Paste: `16:C7:66:7B:38:95:0B:0D:12:3B:6B:B5:90:E8:00:CD:9E:0B:FC:F7`
6. Click **Save**

**For Release (Production):**
When you create a release keystore, get its SHA-1 and add it the same way.

---

## Part 2: iOS Configuration

### Step 1: Verify GoogleService-Info.plist

1. Check that `ios/Runner/GoogleService-Info.plist` exists
2. Verify it contains:
   - `CLIENT_ID`: `45077489966-fja0ov8f5cj061pe71e0ecltp09t9816.apps.googleusercontent.com`
   - `REVERSED_CLIENT_ID`: `com.googleusercontent.apps.45077489966-fja0ov8f5cj061pe71e0ecltp09t9816`
   - `BUNDLE_ID`: `com.lagrangecode.wearit`

### Step 2: Configure Info.plist

1. Open `ios/Runner/Info.plist`
2. Verify `CFBundleURLTypes` contains the REVERSED_CLIENT_ID:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.45077489966-fja0ov8f5cj061pe71e0ecltp09t9816</string>
        </array>
    </dict>
</array>
```

✅ This should already be configured in your project.

### Step 3: Verify in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target
3. Go to **Signing & Capabilities**
4. Verify:
   - **Team** is selected
   - **Bundle Identifier**: `com.lagrangecode.wearit`
   - **GoogleService-Info.plist** is in the project (check in left sidebar)

---

## Part 3: Android Configuration

### Step 1: Verify google-services.json

1. Check that `android/app/google-services.json` exists
2. Verify it contains:
   - `package_name`: `com.lagrangecode.wearit`
   - `mobilesdk_app_id`: `1:45077489966:android:ddbb7794ecdfbe8521f2bf`

### Step 2: Verify build.gradle.kts

**Project-level (`android/build.gradle.kts`):**
Should have Google Services plugin (already configured ✅)

**App-level (`android/app/build.gradle.kts`):**
Should have:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ✅ This should be here
}

android {
    namespace = "com.lagrangecode.wearit"  // ✅ Should match
    defaultConfig {
        applicationId = "com.lagrangecode.wearit"  // ✅ Should match
        minSdk = 21  // ✅ Required for Firebase
    }
}
```

### Step 3: Verify AndroidManifest.xml

Check `android/app/src/main/AndroidManifest.xml`:
- Package name should match: `com.lagrangecode.wearit`
- Internet permission should be present (usually auto-added)

---

## Part 4: Flutter Code Configuration

### Step 1: Verify Dependencies

Check `pubspec.yaml` has:
```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  google_sign_in: ^6.2.1
```

### Step 2: Verify Firebase Initialization

In `lib/main.dart`, Firebase should be initialized with platform-specific options:

```dart
if (Platform.isIOS) {
  options = const FirebaseOptions(
    apiKey: 'AIzaSyAr9b62GyPTE-YGF6VVA76I_7Pe4PQmzY8',
    appId: '1:45077489966:ios:36b9a725b46a855521f2bf',
    messagingSenderId: '45077489966',
    projectId: 'wearit-9b76f',
    storageBucket: 'wearit-9b76f.firebasestorage.app',
    iosBundleId: 'com.lagrangecode.wearit',
  );
} else if (Platform.isAndroid) {
  options = const FirebaseOptions(
    apiKey: 'AIzaSyBp5TxKL7owMy4VrFHJtE727usDe2xcRxk',
    appId: '1:45077489966:android:ddbb7794ecdfbe8521f2bf',
    messagingSenderId: '45077489966',
    projectId: 'wearit-9b76f',
    storageBucket: 'wearit-9b76f.firebasestorage.app',
  );
}
```

### Step 3: Verify Google Sign-In Implementation

The `_signInWithGoogle` method should:
- Use the iOS client ID for iOS
- Handle errors properly
- Sign in to Firebase after Google authentication

✅ This is already implemented in your code.

---

## Part 5: Google Cloud Console (If Needed)

### When to Check Google Cloud Console:

If Google Sign-In still doesn't work after all above steps, check:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **wearit-9b76f**
3. Go to **APIs & Services** → **Credentials**
4. Look for **OAuth 2.0 Client IDs**
5. Verify:
   - **iOS client** exists with bundle ID: `com.lagrangecode.wearit`
   - **Android client** exists with package name: `com.lagrangecode.wearit`

**Note:** Firebase usually manages these automatically, but you can verify here.

---

## Part 6: Testing

### iOS Testing:

1. **Clean build:**
   ```bash
   flutter clean
   cd ios
   pod install
   cd ..
   flutter run
   ```

2. **Test on real device** (recommended) or simulator
3. Tap "Continue with Google"
4. Should see Google sign-in screen
5. After signing in, should navigate to HomeScreen

### Android Testing:

1. **Clean build:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test on device or emulator**
3. Tap "Continue with Google"
4. Should see Google sign-in screen
5. After signing in, should navigate to HomeScreen

---

## Part 7: Troubleshooting

### Common Issues and Solutions:

#### Issue 1: "OAuth client not found"
**Solution:**
- Verify OAuth client exists in Firebase Console
- Re-download `GoogleService-Info.plist` and `google-services.json`
- Ensure bundle ID/package name matches exactly

#### Issue 2: "Invalid client"
**Solution:**
- Check that client ID in code matches `GoogleService-Info.plist`
- Verify URL scheme in `Info.plist` matches REVERSED_CLIENT_ID
- Rebuild the app after changes

#### Issue 3: "Network error"
**Solution:**
- Check internet connection
- Verify Firebase project is active
- Check if there are any Firebase service outages

#### Issue 4: App crashes on Google Sign-In
**Solution:**
- Check console logs for specific error
- Verify all dependencies are installed: `flutter pub get`
- Ensure `GoogleService-Info.plist` is properly added to Xcode project
- Clean and rebuild: `flutter clean && flutter run`

#### Issue 5: "User canceled" (but user didn't)
**Solution:**
- This might be a configuration issue
- Check that Google Sign-In is enabled in Firebase Console
- Verify OAuth consent screen is configured

### Debug Steps:

1. **Check console logs:**
   - Look for: `🔵 Starting Google Sign-In...`
   - Look for: `✅ Google Sign-In account obtained`
   - Look for: `❌ Google Sign-In error: [error]`

2. **Verify Firebase initialization:**
   - Should see: `✅ Firebase initialized successfully`

3. **Test on different devices:**
   - Try on real device vs simulator
   - Try on different iOS/Android versions

---

## Part 8: Verification Checklist

Before testing, verify:

### Firebase Console:
- [ ] Google Sign-In method is **Enabled**
- [ ] iOS app bundle ID: `com.lagrangecode.wearit`
- [ ] Android app package: `com.lagrangecode.wearit`
- [ ] SHA-1 fingerprint added (Android)

### iOS:
- [ ] `GoogleService-Info.plist` in `ios/Runner/`
- [ ] URL scheme in `Info.plist` matches REVERSED_CLIENT_ID
- [ ] Bundle ID in Xcode: `com.lagrangecode.wearit`
- [ ] Development team selected in Xcode

### Android:
- [ ] `google-services.json` in `android/app/`
- [ ] Google Services plugin in `build.gradle.kts`
- [ ] Application ID: `com.lagrangecode.wearit`
- [ ] MinSdk: 21

### Code:
- [ ] Firebase initialized with correct options
- [ ] Google Sign-In uses iOS client ID for iOS
- [ ] Error handling implemented
- [ ] Navigation to HomeScreen after success

---

## Part 9: Quick Fix Commands

If something isn't working, try these in order:

```bash
# 1. Clean everything
flutter clean

# 2. Get dependencies
flutter pub get

# 3. iOS: Reinstall pods
cd ios
pod deintegrate
pod install
cd ..

# 4. Android: Clean Gradle
cd android
./gradlew clean
cd ..

# 5. Rebuild and run
flutter run
```

---

## Part 10: Current Configuration Summary

### Your Current Setup:

**Firebase Project:** `wearit-9b76f`

**iOS:**
- Bundle ID: `com.lagrangecode.wearit`
- App ID: `1:45077489966:ios:36b9a725b46a855521f2bf`
- Client ID: `45077489966-fja0ov8f5cj061pe71e0ecltp09t9816.apps.googleusercontent.com`
- REVERSED_CLIENT_ID: `com.googleusercontent.apps.45077489966-fja0ov8f5cj061pe71e0ecltp09t9816`

**Android:**
- Package: `com.lagrangecode.wearit`
- App ID: `1:45077489966:android:ddbb7794ecdfbe8521f2bf`
- SHA-1: `16:C7:66:7B:38:95:0B:0D:12:3B:6B:B5:90:E8:00:CD:9E:0B:FC:F7`

---

## Next Steps

1. **Follow this guide step by step**
2. **Verify each checklist item**
3. **Test on both platforms**
4. **Check console logs for errors**
5. **Share specific error messages if issues persist**

The code implementation is already correct. The issue is likely in Firebase Console configuration or missing SHA-1 fingerprint for Android.
