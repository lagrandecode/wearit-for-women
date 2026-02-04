# Wearit
Wearit is a fashion and style application that uses AI to generate personalized outfit recommendations based on user photos and preferences. The architecture is designed to be secure, fast, and scalable.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

# Architecture & Tech Stack

## Overview

Wearit is a fashion and style application that uses AI to generate personalized outfit recommendations based on user photos and preferences. The architecture is designed to be secure, fast, and scalable.

## Tech Stack

### Client Layer
- **Flutter** - Cross-platform mobile application framework

### Backend Services
- **Firebase** - Comprehensive backend platform providing:
  - **Firebase Auth** - User authentication (Email, Google, Apple Sign-In)
  - **Firestore** - NoSQL database for user data, preferences, and wardrobe history
  - **Firebase Storage** - Image storage for uploads and generated outfits
  - **Firebase Cloud Messaging (FCM)** - Push notifications
  - **Firebase Analytics** - User behavior tracking

### AI & Processing Layer
- **Vertex AI (Gemini Nano Banana)** - Image editing and reasoning for outfit generation
- **Cloud Run / Cloud Functions** - Secure backend layer for AI processing and shopping integration

---

## High-Level Architecture Flow

### End-to-End User Journey

```
┌─────────────┐
│   Flutter   │
│   Client   │
└─────┬───────┘
      │
      │ 1. User signs in
      ├─────────────────► Firebase Auth
      │
      │ 2. User uploads photo
      ├─────────────────► Firebase Storage
      │
      │ 3. Create job document
      ├─────────────────► Firestore
      │                   (with preferences: outing_type, season, style, budget)
      │
      │ 4. Job status update
      │◄────────────────── Firestore
      │
      │ 5. Receive notification
      │◄────────────────── FCM Push Notification
      │
      │ 6. Display results
      │   (outfit images, wardrobe history, buy links)
```

### Backend Processing Flow

When a new job is created in Firestore, the backend (Cloud Run/Cloud Functions) automatically triggers:

1. **Job Detection**: Cloud Function/Cloud Run detects new job document
2. **Image Retrieval**: Downloads user image from Firebase Storage (or uses signed URL)
3. **AI Processing**: 
   - Calls **Vertex AI Gemini Nano Banana** API
   - Generates outfit image(s) based on user preferences
   - Creates outfit specification JSON (item breakdown)
4. **Product Matching**: 
   - Runs product matching algorithm for user's country
   - Integrates with retailer APIs/affiliate networks
5. **Storage**: 
   - Saves generated outfit images to Firebase Storage
   - Creates thumbnails for faster loading
6. **Database Update**: 
   - Updates Firestore job status (completed)
   - Creates wardrobe history record
   - Stores outfit metadata and product links
7. **Notification**: 
   - Sends FCM push notification: "Your look is ready!"
8. **Client Display**: 
   - Flutter app receives notification
   - Fetches completed job from Firestore
   - Displays outfit images, wardrobe history, and buy links

---

## Firebase Services Breakdown

### Firebase Authentication

**Purpose**: Secure user authentication and session management

**Features**:
- Email/Password authentication
- Google Sign-In (OAuth)
- Apple Sign-In (required for iOS App Store trust)
- Anonymous authentication (optional, for guest browsing)

**Implementation**:
- User profiles stored in Firestore
- Authentication tokens managed by Firebase
- Secure session handling

### Firestore Database

**Purpose**: Store all application data

**Collections Structure**:

```
users/
  {userId}/
    profile: { name, email, preferences }
    preferences: { 
      style: string,
      budget: number,
      favoriteBrands: array,
      size: object
    }

jobs/
  {jobId}/
    userId: string
    status: "pending" | "processing" | "completed" | "failed"
    createdAt: timestamp
    preferences: {
      outing_type: string,
      season_to_shop_for: string,
      style: string,
      budget: number
    }
    originalImageUrl: string
    resultImages: array
    outfitSpec: object
    productMatches: array

wardrobe/
  {wardrobeId}/
    userId: string
    jobId: string
    outfitImages: array
    items: array
    createdAt: timestamp
    tags: array
```

**Use Cases**:
- User profiles and preferences
- Job queue and status tracking
- Wardrobe history
- Outfit metadata and product links

### Firebase Storage

**Purpose**: Store all images (user uploads and AI-generated outfits)

**Bucket Structure**:

```
wearit-app.appspot.com/
  uploads/
    {userId}/
      {jobId}/
        original.jpg
  outfits/
    {userId}/
      {jobId}/
        outfit_1.jpg
        outfit_2.jpg
        thumbnails/
          outfit_1_thumb.jpg
```

**Features**:
- Secure file uploads with authentication
- Image optimization and resizing
- CDN delivery for fast loading
- Signed URLs for temporary access

### Cloud Run / Cloud Functions

**Purpose**: Secure backend layer for AI processing and business logic

**Why Not Client-Side?**
- **Security**: Vertex AI API keys must never be exposed to client
- **Performance**: Heavy image processing should run server-side
- **Cost Control**: Better resource management and cost optimization
- **Scalability**: Auto-scaling based on demand
- **Retailer Integration**: Secure API calls to shopping/affiliate networks

**Cloud Run vs Cloud Functions**:

| Feature | Cloud Functions | Cloud Run |
|---------|----------------|-----------|
| **Best For** | Simple trigger-based workflows | Complex processing, longer tasks |
| **Trigger** | Firestore events, HTTP | HTTP, Pub/Sub, Cloud Tasks |
| **Timeout** | 9 minutes (1st gen) / 60 min (2nd gen) | Up to 60 minutes |
| **Memory** | Up to 8GB | Up to 32GB |
| **Use Case** | Job creation trigger | Image processing, product matching |

**Recommended**: Use **Cloud Run** for this use case because:
- Image processing can be resource-intensive
- Multiple outfit variations may be generated
- Product matching requires multiple API calls
- Better control over execution environment

**Backend Functions**:

1. **`onJobCreated`** (Cloud Function trigger)
   - Triggered when new job document created
   - Validates job data
   - Queues processing task

2. **`processOutfitJob`** (Cloud Run service)
   - Downloads image from Storage
   - Calls Vertex AI for outfit generation
   - Generates outfit spec JSON
   - Runs product matching
   - Uploads results to Storage
   - Updates Firestore job status

3. **`getProductMatches`** (Cloud Run service)
   - Integrates with retailer APIs
   - Filters by user country/preferences
   - Returns product links and metadata

### Vertex AI (Gemini Nano Banana)

**Purpose**: AI-powered outfit generation and style reasoning

**Capabilities**:
- Image-to-image transformation
- Style analysis and recommendations
- Outfit item breakdown generation
- Seasonal/style matching

**Integration**:
- Called from Cloud Run backend (never from client)
- Receives user image + preferences
- Returns generated outfit images + spec JSON

### Firebase Cloud Messaging (FCM)

**Purpose**: Push notifications for job completion and updates

**Notification Types**:
- Job completion: "Your look is ready!"
- New outfit suggestions: "New styles for you"
- Wardrobe updates: "Your wardrobe has been updated"

---

## Security Architecture

### Client-Side Security
- All API keys and secrets stay on backend
- Firebase Auth handles secure authentication
- Signed URLs for temporary image access
- Client only has read/write permissions to user's own data

### Backend Security
- Vertex AI API keys stored in Cloud Secret Manager
- Retailer API keys secured in environment variables
- Firestore security rules enforce data access
- Cloud Run/Functions use service accounts with minimal permissions

### Data Privacy
- User images processed server-side, not stored permanently unless user saves
- GDPR/CCPA compliance through Firebase data controls
- User can delete all data (images, wardrobe, profile)

---

## Scalability Considerations

### Horizontal Scaling
- Cloud Run auto-scales based on request volume
- Firestore handles millions of documents
- Firebase Storage scales automatically

### Performance Optimization
- Image thumbnails for faster loading
- Firestore indexes for common queries
- CDN caching for static assets
- Batch processing for multiple outfit generations

### Cost Optimization
- Cloud Run only charges for active processing time
- Firestore pay-per-use pricing
- Storage tiered pricing for old images
- Vertex AI usage-based billing

---

## Development Workflow

### Local Development
1. Flutter app connects to Firebase (dev project)
2. Use Firebase Emulator Suite for local testing
3. Cloud Run can run locally with Docker

### Staging Environment
- Separate Firebase project for staging
- Test with real Vertex AI (limited calls)
- Full integration testing

### Production
- Production Firebase project
- Cloud Run with production Vertex AI quota
- Monitoring and alerting set up
- Analytics tracking enabled

---

## Next Steps for Implementation

1. **Set up Firebase project** (see Firebase Setup Guide below)
2. **Configure Firestore security rules**
3. **Set up Cloud Run service** for AI processing
4. **Integrate Vertex AI API** in backend
5. **Implement product matching** service
6. **Set up FCM** for notifications
7. **Build Flutter UI** for outfit display and wardrobe

---

# Firebase and Push Notifications Setup Guide

This guide will walk you through setting up Firebase and push notifications for both iOS and Android platforms.

## Prerequisites

- Flutter SDK installed and configured
- Firebase account (create one at [firebase.google.com](https://firebase.google.com))
- Android Studio (for Android setup)
- Xcode (for iOS setup, macOS only)
- Apple Developer account (for iOS push notifications)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or select an existing project
3. Follow the setup wizard:
   - Enter project name: `wearit`
   - Enable/disable Google Analytics (optional)
   - Click **"Create project"**

## Step 2: Install Firebase CLI and FlutterFire CLI

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login
```

## Step 3: Configure Flutter App with Firebase

Run the FlutterFire CLI to automatically configure your app:

```bash
flutterfire configure
```

This will:
- Detect your Firebase projects
- Register your iOS and Android apps
- Download configuration files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS)
- Update your Flutter project

**Note:** Make sure your bundle ID matches:
- Android: `com.lagrangecode.wearit`
- iOS: `com.lagrangecode.wearit`

---

## Android Setup

### Step 1: Add Firebase Dependencies

Add the following to `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^18.0.1
```

Then run:
```bash
flutter pub get
```

### Step 2: Configure Android Project

1. **Update `android/build.gradle`** (project-level):
   ```gradle
   buildscript {
       dependencies {
           classpath 'com.google.gms:google-services:4.4.2'
       }
   }
   ```

2. **Update `android/app/build.gradle`** (app-level):
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   
   android {
       defaultConfig {
           minSdkVersion 21  // Required for Firebase
           targetSdkVersion 34
       }
   }
   
   dependencies {
       implementation platform('com.google.firebase:firebase-bom:33.7.0')
       implementation 'com.google.firebase:firebase-messaging'
   }
   ```

3. **Place `google-services.json`**:
   - Download from Firebase Console → Project Settings → Your Android app
   - Place it in `android/app/google-services.json`

### Step 3: Configure AndroidManifest.xml

Update `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application
        android:label="wearit"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Firebase Cloud Messaging -->
        <service
            android:name="com.google.firebase.messaging.FlutterFirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>
        
        <!-- Notification Channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="high_importance_channel" />
            
    </application>
</manifest>
```

### Step 4: Enable Firebase Cloud Messaging in Firebase Console

1. Go to Firebase Console → Project Settings
2. Click **Cloud Messaging** tab
3. For Android, you're ready to go (no additional setup needed)

---

## iOS Setup

### Step 1: Add Firebase Dependencies

Same as Android - add to `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^18.0.1
```

### Step 2: Configure iOS Project

1. **Place `GoogleService-Info.plist`**:
   - Download from Firebase Console → Project Settings → Your iOS app
   - Open Xcode: `open ios/Runner.xcworkspace`
   - Drag `GoogleService-Info.plist` into the `Runner` folder in Xcode
   - Make sure "Copy items if needed" is checked
   - Ensure it's added to the Runner target

2. **Update `ios/Podfile`**:
   ```ruby
   platform :ios, '12.0'  # Minimum iOS version
   
   target 'Runner' do
     use_frameworks!
     use_modular_headers!
     
     # Firebase pods will be added automatically
   end
   ```

3. **Install CocoaPods dependencies**:
   ```bash
   cd ios
   pod install
   cd ..
   ```

### Step 3: Configure Capabilities in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the **Runner** target
3. Go to **Signing & Capabilities** tab
4. Click **"+ Capability"** and add:
   - **Push Notifications**
   - **Background Modes** (check "Remote notifications")

### Step 4: Update Info.plist

Add to `ios/Runner/Info.plist`:

```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

### Step 5: Enable Push Notifications in Firebase Console

1. Go to Firebase Console → Project Settings → Cloud Messaging
2. Upload your **APNs Authentication Key** or **APNs Certificate**:
   - Go to Apple Developer Portal → Certificates, Identifiers & Profiles
   - Create an APNs Key (recommended) or Certificate
   - Download and upload to Firebase Console

### Step 6: Update AppDelegate.swift

Update `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(_ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
}
```

---

## Flutter Code Implementation

### Step 1: Initialize Firebase in main.dart

Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

// Local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );
  
  // Request notification permissions
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );
  
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else {
    print('User declined or has not accepted permission');
  }
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Get FCM token
  String? token = await messaging.getToken();
  print('FCM Token: $token');
  
  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    
    if (message.notification != null) {
      _showNotification(message);
    }
  });
  
  // Handle notification taps
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('A new onMessageOpenedApp event was published!');
    // Navigate to specific screen based on message data
  });
  
  runApp(const MyApp());
}

void _showNotification(RemoteMessage message) {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.high,
    priority: Priority.high,
  );
  
  const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );
  
  flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title,
    message.notification?.body,
    platformChannelSpecifics,
  );
}
```

### Step 2: Create a Notification Service (Optional)

Create `lib/services/notification_service.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
    // Get FCM token
    String? token = await _messaging.getToken();
    print('FCM Token: $token');
    
    // Save token to your backend/server
    // await saveTokenToServer(token);
  }
  
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
  
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }
  
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}
```

---

## Testing Notifications

### Test from Firebase Console

1. Go to Firebase Console → Cloud Messaging
2. Click **"Send your first message"**
3. Enter notification title and text
4. Click **"Send test message"**
5. Enter your FCM token (printed in console)
6. Click **"Test"**

### Test via API

You can also send notifications using the Firebase Admin SDK or REST API.

---

## Troubleshooting

### Android Issues

- **Notifications not showing**: Check that `POST_NOTIFICATIONS` permission is granted (Android 13+)
- **Build errors**: Ensure `google-services.json` is in `android/app/` directory
- **Token not generated**: Check internet connection and Firebase configuration

### iOS Issues

- **Notifications not working**: Verify APNs key/certificate is uploaded to Firebase
- **Build errors**: Run `pod install` in `ios/` directory
- **Permission denied**: Check Info.plist for notification permissions
- **Token not generated**: Ensure device is registered with Apple Developer account

### General Issues

- **Firebase not initialized**: Make sure `Firebase.initializeApp()` is called before using Firebase services
- **Background messages not working**: Ensure background handler is a top-level function
- **Token is null**: Check device internet connection and Firebase project configuration

---

## Additional Resources

- [Firebase Flutter Documentation](https://firebase.flutter.dev/)
- [Firebase Cloud Messaging Guide](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Console](https://console.firebase.google.com/)

---

## Next Steps

After setting up Firebase and notifications, follow the implementation roadmap:

### Phase 1: Core Firebase Setup
1. ✅ Set up Firebase project and configure Flutter app
2. ✅ Configure push notifications (FCM)
3. Implement Firebase Authentication (Email, Google, Apple Sign-In)
4. Set up Firestore database structure (users, jobs, wardrobe collections)
5. Configure Firestore security rules
6. Set up Firebase Storage buckets and rules

### Phase 2: Backend Infrastructure
7. Set up Cloud Run service for AI processing
8. Integrate Vertex AI (Gemini Nano Banana) API
9. Implement image processing pipeline
10. Build product matching service
11. Set up Cloud Functions triggers for job processing

### Phase 3: Client Implementation
12. Build authentication UI and flows
13. Implement photo upload to Firebase Storage
14. Create job submission flow with preferences
15. Build outfit display UI
16. Implement wardrobe history view
17. Add product links and shopping integration

### Phase 4: Advanced Features
18. Implement topic-based notifications
19. Add notification actions and deep linking
20. Set up Firebase Analytics and crash reporting
21. Implement image optimization and caching
22. Add offline support with Firestore persistence

---

## Recommended Firebase Configuration

Based on the architecture above, here are the recommended Firebase services and their configurations:

### Firebase Auth
- **Enable**: Email/Password, Google, Apple Sign-In
- **Settings**: 
  - Email verification: Optional (can enable later)
  - Password reset: Enabled
  - User blocking: Enabled

### Firestore
- **Location**: Choose closest to your primary user base
- **Mode**: Start with **Native mode** (can upgrade to Datastore mode later if needed)
- **Indexes**: Create composite indexes for:
  - `jobs` collection: `userId + createdAt`
  - `wardrobe` collection: `userId + createdAt`
  - `jobs` collection: `status + createdAt` (for backend processing)

### Firebase Storage
- **Location**: Same region as Firestore
- **Rules**: Restrict access to authenticated users only
- **Lifecycle**: Set up rules to delete old uploads after processing

### Cloud Functions / Cloud Run
- **Region**: Same as Firestore/Storage for low latency
- **Memory**: 2GB minimum (for image processing)
- **Timeout**: 60 minutes (for Cloud Run)
- **Environment Variables**: Store Vertex AI keys in Secret Manager

### Vertex AI Setup
- **API**: Enable Vertex AI API in Google Cloud Console
- **Quota**: Request appropriate quota for production
- **Model**: Gemini Nano Banana for image editing
- **Authentication**: Use service account with Vertex AI User role
