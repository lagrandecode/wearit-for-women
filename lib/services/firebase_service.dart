import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import '../constants/app_constants.dart';

class FirebaseService {
  static Future<void> initialize() async {
    try {
      FirebaseOptions? options;
      
      if (Platform.isIOS) {
        // iOS Firebase configuration
        options = FirebaseOptions(
          apiKey: AppConstants.iosApiKey,
          appId: AppConstants.iosAppId,
          messagingSenderId: AppConstants.firebaseMessagingSenderId,
          projectId: AppConstants.firebaseProjectId,
          storageBucket: AppConstants.firebaseStorageBucket,
          iosBundleId: AppConstants.iosBundleId,
        );
      } else if (Platform.isAndroid) {
        // Android Firebase configuration
        options = FirebaseOptions(
          apiKey: AppConstants.androidApiKey,
          appId: AppConstants.androidAppId,
          messagingSenderId: AppConstants.firebaseMessagingSenderId,
          projectId: AppConstants.firebaseProjectId,
          storageBucket: AppConstants.firebaseStorageBucket,
        );
      }
      
      if (options != null) {
        await Firebase.initializeApp(options: options);
        print('✅ Firebase initialized successfully');
      } else {
        // Fallback: try auto-detection
        await Firebase.initializeApp();
        print('✅ Firebase initialized with auto-detection');
      }
    } catch (e, stackTrace) {
      print('❌ Firebase initialization failed!');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      
      // Try fallback initialization without options
      try {
        print('🔄 Attempting fallback Firebase initialization...');
        await Firebase.initializeApp();
        print('✅ Fallback initialization succeeded');
      } catch (e2) {
        print('❌ Fallback also failed: $e2');
        print('⚠️  App will continue but Firebase features may not work');
      }
    }
  }
}
