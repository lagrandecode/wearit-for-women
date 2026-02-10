# Quick Test: iOS Firebase Notifications

## 🚀 Quick Start (5 Steps)

### 1. Open Xcode
```bash
cd /Volumes/T7/wearit
open ios/Runner.xcworkspace
```

### 2. Configure in Xcode (5 minutes)
- Select **Runner** target → **Signing & Capabilities**
- Add **Push Notifications** capability
- Add **Background Modes** → Check **Remote notifications**
- Select your **Team** for signing

### 3. Upload APNs Key to Firebase (5 minutes)
1. Go to [Apple Developer Portal](https://developer.apple.com/account/) → **Keys**
2. Create new key with **Apple Push Notifications service (APNs)** enabled
3. Download `.p8` file (save Key ID and Team ID)
4. Go to [Firebase Console](https://console.firebase.google.com/) → **Project Settings** → **Cloud Messaging**
5. Upload `.p8` file with Key ID and Team ID

### 4. Build & Run on Physical Device
- Connect iPhone/iPad via USB
- In Xcode, select your device
- Click **Play** button (▶️) or `Cmd + R`
- Grant notification permission when prompted

### 5. Get FCM Token & Send Test
- Check Xcode console for: `FCM Token: <token>`
- Copy the token
- Go to Firebase Console → **Cloud Messaging** → **Send test message**
- Paste token and send!

---

## ✅ Success Indicators

- ✅ FCM token appears in console
- ✅ Notification appears on device
- ✅ No errors in Firebase Console
- ✅ No errors in Xcode console

---

## 📱 Testing Checklist

- [ ] Xcode: Push Notifications capability added
- [ ] Xcode: Background Modes → Remote notifications checked
- [ ] Xcode: Team selected for signing
- [ ] Apple Developer: APNs key created
- [ ] Firebase: APNs key uploaded
- [ ] Device: App installed and running
- [ ] Device: Notification permission granted
- [ ] Console: FCM token generated
- [ ] Firebase: Test notification sent
- [ ] Device: Notification received

---

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| No FCM token | Check internet, verify GoogleService-Info.plist |
| Permission denied | Settings → Wearit → Notifications → Enable |
| APNs failed | Verify key uploaded correctly in Firebase |
| Build errors | Run `cd ios && pod install` |

---

## 📚 Full Guide

See `IOS_FIREBASE_NOTIFICATION_TESTING.md` for detailed instructions.

---

**Note:** App Store Connect is NOT needed for testing. Only needed for production/TestFlight.
