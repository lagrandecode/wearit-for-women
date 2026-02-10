# iOS Firebase Notification Testing Guide

This guide will help you test if iOS Firebase Cloud Messaging (FCM) notifications are properly configured.

---

## Prerequisites Checklist

Before testing, ensure you have:
- ✅ Apple Developer Account (free account works for development)
- ✅ Xcode installed (latest version recommended)
- ✅ Physical iOS device (notifications don't work on simulator)
- ✅ Firebase project configured
- ✅ `GoogleService-Info.plist` in your project

---

## Part 1: Xcode Configuration

### Step 1: Open Project in Xcode

```bash
cd /Volumes/T7/wearit
open ios/Runner.xcworkspace
```

**Important:** Always open `.xcworkspace`, NOT `.xcodeproj`

### Step 2: Verify GoogleService-Info.plist

1. In Xcode's left sidebar, find `Runner` folder
2. Look for `GoogleService-Info.plist`
3. If it's missing:
   - Download from Firebase Console → Project Settings → Your iOS app
   - Drag it into the `Runner` folder in Xcode
   - Make sure "Copy items if needed" is checked
   - Ensure it's added to the Runner target

### Step 3: Configure Signing & Capabilities

1. In Xcode, select **Runner** project (top of left sidebar)
2. Select **Runner** target (under TARGETS)
3. Go to **Signing & Capabilities** tab
4. Configure **Signing**:
   - ✅ Check "Automatically manage signing"
   - Select your **Team** (your Apple Developer account)
   - Verify **Bundle Identifier**: `com.lagrangecode.wearit`
   - If you see errors, click "Try Again" or manually select your team

5. Add **Push Notifications** capability:
   - Click **"+ Capability"** button (top left)
   - Search for "Push Notifications"
   - Click to add it
   - ✅ You should see "Push Notifications" added

6. Add **Background Modes** capability:
   - Click **"+ Capability"** again
   - Search for "Background Modes"
   - Click to add it
   - ✅ Check the box: **"Remote notifications"**

### Step 4: Verify Info.plist

Your `Info.plist` should already have:
- ✅ `UIBackgroundModes` with `remote-notification` (already configured)

### Step 5: Check AppDelegate (if exists)

If you have `ios/Runner/AppDelegate.swift`, it should handle notifications. If not, Flutter handles it automatically.

---

## Part 2: Apple Developer Portal - APNs Configuration

### Step 1: Create APNs Authentication Key (Recommended)

**Why?** APNs Key is easier to manage than certificates and works for all apps.

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Sign in with your Apple Developer account
3. Navigate to **Certificates, Identifiers & Profiles**
4. Click **Keys** (left sidebar)
5. Click **"+"** button (top right) to create a new key
6. Fill in:
   - **Key Name**: `Wearit APNs Key` (or any name)
   - ✅ Check **"Apple Push Notifications service (APNs)"**
7. Click **Continue** → **Register**
8. **Download the key** (`.p8` file) - **YOU CAN ONLY DOWNLOAD ONCE!**
9. **Note the Key ID** (e.g., `K378AU4SZJ`)
10. **Note your Team ID** (found at top right of Apple Developer Portal, e.g., `2RX956H8MF`)

### Step 2: Upload APNs Key to Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **wearit-9b76f**
3. Go to **Project Settings** (gear icon) → **Cloud Messaging** tab
4. Scroll to **Apple app configuration**
5. Under **APNs Authentication Key**:
   - Click **Upload**
   - Select your `.p8` file (the key you downloaded)
   - Enter **Key ID** (e.g., `K378AU4SZJ`)
   - Enter **Team ID** (e.g., `2RX956H8MF`)
   - Click **Upload**

✅ You should see a green checkmark indicating the key is uploaded.

**Alternative: APNs Certificate (if you prefer)**
- Follow similar steps but create an APNs Certificate instead
- Upload the certificate to Firebase Console

---

## Part 3: App Store Connect (Optional for Testing)

**Note:** App Store Connect is only needed for:
- Production push notifications
- TestFlight distribution
- App Store submission

**For development/testing:** You don't need App Store Connect. You can test with:
- Development build on a physical device
- Ad-hoc distribution (if you have a paid Apple Developer account)

### If You Need App Store Connect:

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Create your app (if not already created)
3. Configure App ID with Push Notifications enabled
4. This is automatically done when you add Push Notifications capability in Xcode

---

## Part 4: Build and Run on Physical Device

### Step 1: Connect Your iPhone/iPad

1. Connect your iOS device via USB
2. Unlock your device
3. Trust the computer if prompted

### Step 2: Select Device in Xcode

1. In Xcode, at the top toolbar, click the device selector
2. Select your connected device (e.g., "John's iPhone")

### Step 3: Build and Run

**Option A: From Xcode**
1. Click the **Play** button (▶️) or press `Cmd + R`
2. Wait for build to complete
3. App will install and launch on your device

**Option B: From Terminal**
```bash
cd /Volumes/T7/wearit
flutter run -d <device-id>
```

To find device ID:
```bash
flutter devices
```

### Step 4: Grant Notification Permission

1. When the app launches, it will request notification permission
2. Tap **"Allow"** or **"Allow Notifications"**
3. ✅ Permission granted!

---

## Part 5: Get FCM Token for Testing

### Method 1: Check Console Logs

1. Run the app on your device
2. In Xcode, open **Console** (View → Debug Area → Activate Console)
3. Look for: `FCM Token: <your-token-here>`
4. Copy the token

### Method 2: Add Debug Code (Temporary)

Add this to your app temporarily to display the token:

```dart
// In home_screen.dart or any screen, add:
Future<void> _showFCMToken() async {
  final token = await NotificationService.getFCMToken();
  if (token != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('FCM Token: $token'),
        duration: Duration(seconds: 10),
      ),
    );
    print('FCM Token: $token');
  }
}
```

Call this method when the app loads to see the token.

---

## Part 6: Send Test Notification from Firebase Console

### Step 1: Open Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **wearit-9b76f**
3. Click **Cloud Messaging** (left sidebar, under "Engage")

### Step 2: Send Test Message

1. Click **"Send your first message"** or **"New campaign"**
2. Click **"Send test message"** (top right)
3. In the dialog:
   - **FCM registration token**: Paste your FCM token (from Step 5)
   - **Notification title**: `Test Notification`
   - **Notification text**: `This is a test from Firebase!`
4. Click **"Test"**

### Step 3: Verify Notification

1. **If app is in foreground**: Check console logs for the message
2. **If app is in background**: You should see a notification banner
3. **If app is closed**: You should see a notification on the lock screen

✅ **Success indicators:**
- Notification appears on your device
- No errors in Firebase Console
- No errors in Xcode console

---

## Part 7: Troubleshooting

### Issue 1: "No FCM Token Generated"

**Solutions:**
- ✅ Ensure device has internet connection
- ✅ Check that `GoogleService-Info.plist` is correct
- ✅ Verify APNs key is uploaded to Firebase
- ✅ Make sure you're testing on a **physical device** (not simulator)
- ✅ Check Xcode console for errors

### Issue 2: "Permission Denied"

**Solutions:**
- ✅ Go to iPhone Settings → Wearit → Notifications
- ✅ Enable "Allow Notifications"
- ✅ Re-run the app

### Issue 3: "APNs Authentication Failed"

**Solutions:**
- ✅ Verify APNs key is uploaded correctly in Firebase Console
- ✅ Check Key ID and Team ID are correct
- ✅ Ensure the `.p8` file is valid (not corrupted)
- ✅ Try creating a new APNs key

### Issue 4: "Notification Not Received"

**Solutions:**
- ✅ Verify FCM token is correct (copy-paste carefully)
- ✅ Check device has internet connection
- ✅ Ensure app has notification permission
- ✅ Try sending notification when app is in background (not foreground)
- ✅ Check Firebase Console for delivery status

### Issue 5: "Build Errors in Xcode"

**Solutions:**
- ✅ Run `cd ios && pod install && cd ..`
- ✅ Clean build folder: Product → Clean Build Folder (`Cmd + Shift + K`)
- ✅ Restart Xcode
- ✅ Check that all capabilities are properly added

---

## Part 8: Verify Configuration Checklist

Use this checklist to verify everything is set up:

### Xcode Configuration
- [ ] Project opens in Xcode without errors
- [ ] `GoogleService-Info.plist` is in project
- [ ] Signing & Capabilities shows your Team
- [ ] Bundle ID is `com.lagrangecode.wearit`
- [ ] **Push Notifications** capability is added
- [ ] **Background Modes** → **Remote notifications** is checked

### Apple Developer Portal
- [ ] APNs Authentication Key created
- [ ] Key ID noted
- [ ] Team ID noted
- [ ] `.p8` file downloaded

### Firebase Console
- [ ] APNs key uploaded to Firebase
- [ ] Cloud Messaging is enabled
- [ ] No errors shown in Firebase Console

### Device Testing
- [ ] App builds and runs on physical device
- [ ] Notification permission is granted
- [ ] FCM token is generated (check console)
- [ ] Test notification is received

---

## Part 9: Testing Local Notifications (Bonus)

Your app also has local notifications for outfit reminders. To test:

1. Open the app
2. Go to **Planner** screen
3. Select a date
4. Select a time (e.g., 2 minutes from now)
5. Upload an outfit image
6. Wait for the notification (scheduled 15 minutes before, but you can test with a closer time)

---

## Quick Test Command

After configuring everything, run this to test:

```bash
# 1. Build and run on device
flutter run -d <your-device-id>

# 2. Check console for FCM token
# 3. Copy token and send test from Firebase Console
```

---

## Next Steps

Once notifications are working:
1. ✅ Remove any debug code that displays FCM tokens
2. ✅ Test with app in different states (foreground, background, closed)
3. ✅ Test notification actions (if you add them later)
4. ✅ Set up notification handling for when user taps notification

---

## Support Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Apple Push Notifications Guide](https://developer.apple.com/documentation/usernotifications)
- [Flutter Firebase Messaging Package](https://pub.dev/packages/firebase_messaging)

---

**Last Updated:** Based on your current project configuration
**Project:** wearit-9b76f
**Bundle ID:** com.lagrangecode.wearit
