import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../constants/app_constants.dart';

class AuthService {
  // Apple Sign-In
  static Future<UserCredential?> signInWithApple(BuildContext context) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      // User canceled or authorization failed - don't show error
      // Check if the error code indicates cancellation
      if (e.code.toString().contains('canceled') || 
          e.code.toString().contains('cancel')) {
        print('ℹ️ User canceled Apple Sign-In');
        return null;
      }
      // Other authorization errors - rethrow to be handled by caller
      rethrow;
    } catch (e) {
      // Only return null if it's a cancellation
      if (e.toString().contains('canceled') || 
          e.toString().contains('cancel') ||
          e.toString().contains('user_cancelled')) {
        print('ℹ️ User canceled Apple Sign-In');
        return null;
      }
      rethrow;
    }
  }

  // Google Sign-In
  static Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      // Configure Google Sign-In with iOS client ID
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // For iOS, specify the client ID explicitly
        clientId: Platform.isIOS ? AppConstants.iosClientId : null,
      );
      
      print('🔵 Starting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('⚠️ User canceled Google Sign-In');
        return null;
      }

      print('✅ Google Sign-In account obtained: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Failed to get ID token from Google Sign-In');
      }

      print('✅ Google authentication tokens obtained');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔵 Signing in to Firebase with Google credential...');
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      print('✅ Successfully signed in: ${userCredential.user?.email}');
      return userCredential;
    } catch (e, stackTrace) {
      print('❌ Google Sign-In error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Email/Password Sign-In
  static Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Email/Password Sign-Up
  static Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign Out
  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (Platform.isIOS) {
      await GoogleSignIn().signOut();
    }
  }

  // Get Current User
  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }
}
