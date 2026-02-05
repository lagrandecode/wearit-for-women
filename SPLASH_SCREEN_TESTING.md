# Testing Native Splash Screen

## Quick Test Methods

### Method 1: Cold Start (Recommended)
The splash screen appears when the app is launched from a completely closed state.

**Steps:**
1. **Close the app completely** (not just minimize)
   - Android: Swipe away from recent apps or use "Force Stop" in Settings
   - iOS: Swipe up from bottom and swipe away the app
2. **Launch the app again** from the home screen
3. You should see the splash screen with:
   - `wearit.png` logo centered
   - White background (if device is in light mode)
   - Black background (if device is in dark mode)

### Method 2: Test Dark Mode
To verify dark mode splash screen:

**Android:**
1. Go to Settings → Display → Dark theme (or similar)
2. Enable dark mode
3. Close and reopen the app

**iOS:**
1. Go to Settings → Display & Brightness
2. Select "Dark" appearance
3. Close and reopen the app

### Method 3: Build and Install Fresh
For a clean test, build a fresh release:

```bash
# Android
flutter build apk --release
# Then install on device and launch

# iOS
flutter build ios --release
# Then install via Xcode or TestFlight
```

## What to Look For

### ✅ Working Correctly:
- Logo appears immediately when app launches
- Background color matches system theme (white/black)
- Smooth transition from splash to app
- No white/blank flash before splash appears

### ❌ Not Working:
- White/blank screen before app loads
- Logo doesn't appear
- Background color doesn't match theme
- App loads too fast to see splash

## Troubleshooting

### If splash screen doesn't appear:

1. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   dart run flutter_native_splash:create
   flutter run
   ```

2. **Check configuration in `pubspec.yaml`:**
   - Verify `image: assets/images/wearit.png` exists
   - Verify `color: "#FFFFFF"` and `color_dark: "#000000"` are set
   - Verify `ios: true` and `android: true` are set

3. **Verify assets exist:**
   ```bash
   ls assets/images/wearit.png
   ```

4. **Check Android manifest:**
   - Ensure `android/app/src/main/res/values/styles.xml` exists
   - Ensure `android/app/src/main/res/drawable/launch_background.xml` exists

5. **Check iOS assets:**
   - Ensure `ios/Runner/Assets.xcassets/LaunchImage.imageset/` exists
   - Ensure `ios/Runner/Base.lproj/LaunchScreen.storyboard` exists

## Testing on Different Devices

### Android:
- Test on Android 12+ for new splash screen API
- Test on older Android versions for compatibility
- Test in both light and dark modes

### iOS:
- Test on iOS 13+ for dark mode support
- Test on different screen sizes (iPhone, iPad)
- Test in both light and dark modes

## Quick Visual Test

1. **Set device to light mode** → Launch app → Should see white background
2. **Set device to dark mode** → Launch app → Should see black background
3. **Logo should be visible** in both cases

## Debug Mode Note

In debug mode, the splash screen might appear very briefly because:
- Hot reload keeps the app in memory
- Debug builds load faster

For best testing, use **release builds** or **cold starts** (completely close the app first).
