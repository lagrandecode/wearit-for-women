import 'package:flutter/material.dart';
import 'secrets.dart';

class AppConstants {
  // Colors
  static const primaryColor = 0xFFFE9ECD;
  static const successColor = Colors.purple; // Purple for success messages (women-focused app)
  
  // Firebase Configuration
  static const firebaseProjectId = 'wearit-9b76f';
  static const firebaseMessagingSenderId = '45077489966';
  static const firebaseStorageBucket = 'wearit-9b76f.firebasestorage.app';
  
  // iOS Firebase Configuration
  static const iosApiKey = Secrets.iosApiKey;
  static const iosAppId = '1:45077489966:ios:36b9a725b46a855521f2bf';
  static const iosBundleId = 'com.lagrangecode.wearit';
  static const iosClientId = '45077489966-fja0ov8f5cj061pe71e0ecltp09t9816.apps.googleusercontent.com';
  
  // Android Firebase Configuration
  static const androidApiKey = Secrets.androidApiKey;
  static const androidAppId = '1:45077489966:android:ddbb7794ecdfbe8521f2bf';
  static const androidPackageName = 'com.lagrangecode.wearit';
  
  // Assets
  static const videoAssetPath = 'assets/videos/intro22.mp4';
  
  // Vertex AI Configuration
  // ⚠️ WARNING: API keys are stored in secrets.dart (gitignored)
  static const String? vertexAiAccessToken = Secrets.vertexAiAccessToken;
  static const String? vertexAiApiKey = Secrets.vertexAiApiKey;
  static const String vertexAiRegion = 'us-central1';
}
