import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Service for handling both Firebase Cloud Messaging and Local Notifications
class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Background message handler (must be top-level function)
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
  }

  /// Initialize notification service
  static Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();
    
    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    // Request notification permissions
    await _requestPermissions();

    // Set up Firebase Cloud Messaging
    await _setupFirebaseMessaging();
  }

  /// Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel outfitReminderChannel = AndroidNotificationChannel(
      'outfit_reminders',
      'Outfit Reminders',
      description: 'Notifications for planned outfit reminders',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(outfitReminderChannel);
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    // Request FCM permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else {
      print('User declined or has not accepted notification permission');
    }

    // Request iOS permissions for local notifications
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Set up Firebase Cloud Messaging
  static Future<void> _setupFirebaseMessaging() async {
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Try to get FCM token (only works on physical devices, not simulators)
    try {
      // First, try to get APNs token (iOS only, and only on physical devices)
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      
      if (apnsToken != null) {
        // APNs token is available, now we can get FCM token
        String? token = await _firebaseMessaging.getToken();
        print('FCM Token: $token');
      } else {
        print('⚠️  APNs token not available. This is normal on iOS simulators.');
        print('⚠️  FCM tokens are only available on physical iOS devices.');
        print('⚠️  Push notifications will not work on simulator.');
      }
    } catch (e) {
      // Handle the case where APNs token is not set (simulator or not configured)
      if (e.toString().contains('apns-token-not-set')) {
        print('⚠️  APNs token not set. This is normal on iOS simulators.');
        print('⚠️  To test push notifications, use a physical iOS device.');
      } else {
        print('⚠️  Error getting FCM token: $e');
      }
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      _showLocalNotification(
        title: message.notification?.title ?? 'New Message',
        body: message.notification?.body ?? '',
        payload: message.data.toString(),
      );
    });

    // Handle notification taps when app is opened from terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle navigation based on payload if needed
  }

  /// Handle Firebase notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    // Handle navigation based on message data if needed
  }

  /// Show a local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'outfit_reminders',
      'Outfit Reminders',
      channelDescription: 'Notifications for planned outfit reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Schedule a local notification for outfit reminder
  /// 
  /// [id] - Unique notification ID (use date timestamp to ensure uniqueness)
  /// [title] - Notification title
  /// [body] - Notification body
  /// [scheduledDate] - Date and time when notification should be shown
  static Future<void> scheduleOutfitReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Don't schedule if the date is in the past
    if (scheduledDate.isBefore(DateTime.now())) {
      print('Cannot schedule notification in the past');
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'outfit_reminders',
      'Outfit Reminders',
      channelDescription: 'Notifications for planned outfit reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Convert DateTime to TZDateTime (local timezone)
    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);

    try {
      // Schedule notification using zonedSchedule
      // No matchDateTimeComponents - this is a one-time notification for a specific date
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTZ,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('✅ Scheduled notification for ${scheduledDate.toString()} (ID: $id)');
      print('   Local time: ${DateTime.now()}');
      print('   Scheduled time: $scheduledTZ');
      print('   Time difference: ${scheduledTZ.difference(tz.TZDateTime.now(tz.local)).inMinutes} minutes');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
      print('   ID: $id');
      print('   Scheduled date: $scheduledDate');
      print('   TZDateTime: $scheduledTZ');
      rethrow;
    }
  }

  /// Cancel a scheduled notification
  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
    print('Cancelled notification with id: $id');
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    print('Cancelled all notifications');
  }


  /// Get FCM token
  /// Returns null if APNs token is not available (e.g., on iOS simulator)
  static Future<String?> getFCMToken() async {
    try {
      // Check if APNs token is available first (iOS only)
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      if (apnsToken == null) {
        print('⚠️  APNs token not available. Cannot get FCM token.');
        print('⚠️  This is normal on iOS simulators. Use a physical device.');
        return null;
      }
      
      // APNs token is available, get FCM token
      return await _firebaseMessaging.getToken();
    } catch (e) {
      if (e.toString().contains('apns-token-not-set')) {
        print('⚠️  APNs token not set. Cannot get FCM token.');
        print('⚠️  This is normal on iOS simulators. Use a physical device.');
        return null;
      }
      print('⚠️  Error getting FCM token: $e');
      return null;
    }
  }
}
